class AiCoachService
  def initialize
    @gemini  = GeminiClient.new
    @embedder = EmbeddingService.new
  end

  def generate_program(objectives:, user: nil, mode: "program")
    book_context    = retrieve_context(objectives)
    client_profile  = build_client_profile(user)
    exercises_list  = Rails.cache.fetch("exercises_list", expires_in: 1.hour) do
      Exercise.all.pluck(:name, :muscle_group).map { |n, mg| "#{n} (#{mg})" }.join(", ")
    end

    system_prompt = build_system_prompt(mode)
    user_prompt   = build_generation_prompt(
      objectives:     objectives,
      book_context:   book_context,
      client_profile: client_profile,
      exercises_list: exercises_list,
      mode:           mode
    )

    response_text   = @gemini.call(system_prompt, user_prompt)
    structured_data = @gemini.parse_json(response_text)

    conversation = AiConversation.create!(
      user:           user,
      title:          structured_data.dig("program", "name") || "AI Generated #{mode.capitalize}",
      objectives:     objectives,
      generated_data: structured_data
    )

    conversation.add_message!(role: "user", content: objectives)
    conversation.add_message!(role: "assistant", content: response_text, structured_data: structured_data)

    { conversation: conversation, structured_data: structured_data }
  end

  def refine(conversation:, message:, mode: "program", program_context: nil)
    book_context  = mode == "program_chat" ? nil : retrieve_context(message)
    history       = mode == "program_chat" ? [] : conversation.message_history
    latest_data   = program_context || conversation.generated_data

    refinement_prompt = if mode == "program_chat"
      <<~PROMPT
        Programa actual (solo para contexto):
        #{latest_data.to_json}

        Solicitud del coach: "#{message}"

        Devolvé ÚNICAMENTE el JSON de modificaciones según las instrucciones del sistema.
      PROMPT
    else
      <<~PROMPT
        The coach wants to modify the previously generated program.

        Previous program (JSON):
        #{latest_data.to_json}

        #{book_context ? "Additional book knowledge for this refinement:\n        #{book_context}\n" : ""}Coach's request: "#{message}"

        Please return the COMPLETE updated program as JSON, incorporating the requested changes.
        Keep the same JSON structure. Only modify what the coach asked for.
        Return ONLY valid JSON, no markdown fences.
      PROMPT
    end

    system_prompt   = build_system_prompt(mode)
    response_text   = @gemini.call(system_prompt, refinement_prompt, history: history)
    structured_data = @gemini.parse_json(response_text)

    conversation.add_message!(role: "user", content: message)
    conversation.add_message!(role: "assistant", content: response_text, structured_data: structured_data)
    conversation.update!(generated_data: structured_data)

    { conversation: conversation, structured_data: structured_data }
  end

  def rank_programs(shortlist, user)
    client_profile = build_client_profile(user)
    serialized     = shortlist.map { |t| { name: t.name, description: t.description, duration_weeks: t.duration_weeks } }

    prompt = <<~PROMPT
      Client profile:
      #{client_profile}

      Available programs:
      #{serialized.to_json}

      Return only the name of the program from the list that best fits this client's profile.
    PROMPT

    response   = @gemini.call("You are a fitness program matcher. Return ONLY the program name, nothing else.", prompt)
    matched    = response&.strip&.downcase
    shortlist.find { |t| t.name.strip.downcase == matched }
  end

  def create_records!(conversation)
    result = ProgramRecordBuilder.new(conversation.generated_data, conversation.user).build!
    program = result.is_a?(Program) ? result : nil
    conversation.update!(status: "completed", program: program)
    result
  end

  def build_client_profile(user)
    return "No specific client selected. Generate a general template." unless user

    profile = user.onboarding_profile

    base = <<~BASE
      CLIENT PROFILE:
      - Name: #{user.name}
      - Category: #{user.category}
      - Status: #{user.status}
      - Current Weight (logged): #{user.latest_weight || 'Not logged'}
      - Weight Trend (7d): #{user.weight_trend || 'N/A'}
      - Workout Compliance: #{user.calculate_workout_compliance_score}%
      - Diet Adherence: #{user.calculate_diet_adherence_score}%
      - Current Programs: #{user.programs.map(&:name).join(', ').presence || 'None'}
      - Target Workouts/Week: #{user.target_workouts_per_week}
    BASE

    return base unless profile

    base + <<~ONBOARDING

      ONBOARDING QUESTIONNAIRE:
      - Gender: #{profile.gender}
      - Age: #{profile.age}
      - Weight (self-reported): #{profile.weight}
      - Height: #{profile.height}
      - Goals: #{Array(profile.goals).join(', ').presence || 'Not specified'}
      - Training Experience Level: #{profile.experience_level}/10
      - Best Lifts: #{profile.best_lifts.presence || 'Not specified'}
      - Commitment Level: #{profile.commitment_level}
      - Training Frequency: #{profile.training_frequency} days/week
      - Time per Session: #{profile.time_per_session.presence || 'Not specified'}
      - Injuries / Limitations: #{profile.injuries.presence || 'None reported'}
      - Plays Sports: #{profile.plays_sports}#{profile.plays_sports == 'Si' && profile.sport_details.present? ? " (#{profile.sport_details})" : ''}
      - Diet Quality: #{profile.diet_quality}
      - Daily Activity Level: #{profile.activity_level}
      - Sleep: #{profile.sleep_hours} hours/night
    ONBOARDING
  end

  private

  def retrieve_context(query)
    query_embedding = @embedder.embed(query)
    return "No book knowledge available." unless query_embedding

    chunks = BookChunk.search(query_embedding, limit: 10)
    return "No relevant book knowledge found for this query." if chunks.none?

    chunks.map.with_index do |chunk, i|
      "[Source #{i + 1} - #{chunk.book.title}, p.#{chunk.page_number}]\n#{chunk.content}"
    end.join("\n\n")
  end

  def build_system_prompt(mode)
    base = <<~BASE
      You are an expert fitness program designer assistant. You help coaches create
      evidence-based training programs by combining scientific knowledge from fitness
      literature with practical coaching experience.

      Your output MUST be valid JSON only. Do not include any markdown code fences (like ```json).
      Do not include any conversational text, headers, or footers.
      Start your response with '{' and end with '}'.

      When suggesting exercises, prefer using existing exercises from the coach's database
      when they match. For new exercises, provide a clear name and muscle group.

      Structure your programs with progressive overload principles, appropriate volume,
      and clear periodization. Consider the client's current fitness level and goals.

      Always include practical instructions for each exercise to guide execution.

      IMPORTANT: All program names, descriptions, and instructions MUST be written in Spanish.
      This includes the program name, routine names, workout descriptions, exercise instructions,
      and dietary plan information. The audience is Argentine/Spanish-speaking clients.
    BASE

    return base unless mode == "program_chat"

    <<~CHAT
      Sos un AI Coach de fitness especializado en modificaciones de programas de entrenamiento.
      Respondés ÚNICAMENTE con un JSON válido. Sin texto conversacional, sin markdown, sin explicaciones.
      Empezá con '{' y terminá con '}'.

      Devolvé ÚNICAMENTE este esquema con los cambios solicitados:
      {
        "summary": "Descripción breve de los cambios en español",
        "modifications": [
          { "workout_exercise_id": <id_existente>, <solo_los_campos_que_cambian> },
          { "workout_exercise_id": null, "replace_workout_exercise_id": <id_a_eliminar_o_null>, "workout_id": <id>, "name": "...", "muscle_group": "...", "sets": ..., "reps": "...", "rest_seconds": ..., "load": "..." }
        ]
      }

      Reglas:
      - Para modificar atributos: workout_exercise_id con el id + solo los campos que cambian.
      - Para reemplazar un ejercicio: workout_exercise_id null + replace_workout_exercise_id con el id del ejercicio a eliminar + workout_id del workout padre.
      - Para agregar un ejercicio nuevo sin reemplazar: workout_exercise_id null + replace_workout_exercise_id null + workout_id.
      - No agregues workouts ni rutinas nuevas.
      - NO devuelvas el programa completo. Solo el array de modificaciones y el summary.
    CHAT
  end

  def build_generation_prompt(objectives:, book_context:, client_profile:, exercises_list:, mode:)
    json_schema = generation_json_schema(mode)

    <<~PROMPT
      #{client_profile}

      COACH'S OBJECTIVES:
      #{objectives}

      KNOWLEDGE FROM FITNESS BOOKS:
      #{book_context}

      AVAILABLE EXERCISES IN DATABASE:
      #{exercises_list}

      Please generate a #{mode == 'routine' ? 'single routine' : 'complete training program'} based on
      the above information. Use the exact JSON structure below.

      IMPORTANT FORMATTING CONSTRAINT:
      If the user asks for a long-term program (e.g. 6 months), DO NOT generate individual workouts for every single day of those 6 months. Instead, generate a typical microcycle (e.g., 1 week of unique workout days mapped into a routine) and simply assign the appropriately large number to the `duration_weeks` fields. For example, a 5-day-per-week program should output exactly 5 workouts inside the routine representing the recurring weekly split.

      For exercises, if an exercise already exists in the database, use its exact name.
      If you need to suggest a new exercise, provide a descriptive name and muscle_group.
      Set "existing_exercise_id" to null for new exercises.

      REQUIRED JSON STRUCTURE:
      #{json_schema}

      Return ONLY the JSON. No explanations, no markdown fences.
    PROMPT
  end

  def generation_json_schema(mode)
    program_block = mode == "program" ? <<~PROGRAM
        "program": {
          "name": "string",
          "description": "string (detailed program overview)",
          "duration_weeks": integer
        },
    PROGRAM
    : ""

    <<~JSON
      {
    #{program_block.chomp}
        "routines": [
          {
            "name": "string (e.g. 'Push/Pull/Legs 1')",
            "description": "string",
            "duration_weeks": integer,
            "workouts": [
              {
                "name": "string (e.g. 'Upper Body Push')",
                "description": "string or null",
                "day_number": integer,
                "exercises": [
                  {
                    "name": "string (exact name if existing, descriptive if new)",
                    "muscle_group": "string — MUST be one of: #{Exercise::MUSCLE_GROUPS.join(', ')}",
                    "existing_exercise_id": integer_or_null,
                    "sets": integer,
                "warmup_sets": "string (e.g. '1-2' or '0')",
                "reps": "string (e.g. '8-10' or '12')",
                "load": "string (e.g. 'Bodyweight', '60kg', 'RPE 8', 'AMRAP') or null",
                "early_rpe": "string (e.g. '~7')",
                "last_rpe": "string (e.g. '~8')",
                "rest_seconds": integer,
                "intensity_technique": "string (e.g. 'Lengthened Partials', 'Drop Set') or null",
                "time_estimate": "string (e.g. '8-10 min')",
                "sub_option_one": "string or null",
                "sub_option_two": "string or null"
              }
            ]
          }
        ]
      }
    ],
    "dietary_plan": {
      "name": "string",
      "description": "string",
      "calories_target": integer,
      "protein_target": integer
    }
  }
    JSON
  end
end
