require "net/http"
require "uri"
require "json"

class AiCoachService
  GENERATION_MODEL = "gemini-2.0-flash"

  def initialize
    @api_key = ENV["GEMINI_API_KEY"]
    @embedding_service = EmbeddingService.new
    @base_url = "https://generativelanguage.googleapis.com/v1beta/models/#{GENERATION_MODEL}:generateContent"
  end

  # Generate a program/routine from objectives with RAG context
  # Returns { conversation: AiConversation, structured_data: Hash }
  def generate_program(objectives:, user: nil, mode: "program")
    # 1. Retrieve relevant book knowledge
    book_context = retrieve_context(objectives)

    # 2. Build the client profile (if user provided)
    client_profile = build_client_profile(user)

    # 3. Build available exercises
    exercises_list = Exercise.all.pluck(:name, :muscle_group).map { |n, mg| "#{n} (#{mg})" }.join(", ")

    # 4. Construct system prompt
    system_prompt = build_system_prompt(mode)

    # 5. Construct user prompt
    user_prompt = build_generation_prompt(
      objectives: objectives,
      book_context: book_context,
      client_profile: client_profile,
      exercises_list: exercises_list,
      mode: mode
    )

    # 6. Call Gemini
    response_text = call_gemini(system_prompt, user_prompt)
    structured_data = parse_json_response(response_text)

    # 7. Create conversation record
    conversation = AiConversation.create!(
      user: user,
      title: structured_data.dig("program", "name") || "AI Generated #{mode.capitalize}",
      objectives: objectives,
      generated_data: structured_data
    )

    conversation.add_message!(role: "user", content: objectives)
    conversation.add_message!(
      role: "assistant",
      content: response_text,
      structured_data: structured_data
    )

    { conversation: conversation, structured_data: structured_data }
  end

  # Refine an existing conversation with a new message
  def refine(conversation:, message:)
    book_context = retrieve_context(message)

    history = conversation.message_history
    latest_data = conversation.generated_data

    refinement_prompt = <<~PROMPT
      The coach wants to modify the previously generated program.

      Previous program (JSON):
      #{latest_data.to_json}

      Additional book knowledge for this refinement:
      #{book_context}

      Coach's request: "#{message}"

      Please return the COMPLETE updated program as JSON, incorporating the requested changes.
      Keep the same JSON structure. Only modify what the coach asked for.
      Return ONLY valid JSON, no markdown fences.
    PROMPT

    system_prompt = build_system_prompt("program")
    response_text = call_gemini(system_prompt, refinement_prompt, history: history)
    structured_data = parse_json_response(response_text)

    # Update conversation
    conversation.add_message!(role: "user", content: message)
    conversation.add_message!(
      role: "assistant",
      content: response_text,
      structured_data: structured_data
    )
    conversation.update!(generated_data: structured_data)

    { conversation: conversation, structured_data: structured_data }
  end

  # Create actual database records from the structured data
  def create_records!(conversation)
    data = conversation.generated_data
    user = conversation.user

    ActiveRecord::Base.transaction do
      program = nil

      # Create Program if present
      if data["program"]
        program = Program.create!(
          name: data["program"]["name"],
          description: data["program"]["description"],
          duration_weeks: data["program"]["duration_weeks"],
          user: user
        )
      end

      # Create Routines
      data["routines"]&.each do |routine_data|
        routine = Routine.create!(
          name: routine_data["name"],
          description: routine_data["description"],
          duration_weeks: routine_data["duration_weeks"],
          is_template: user.nil?,
          user: user,
          program: program
        )

        # Create Exercises and RoutineExercises
        routine_data["exercises"]&.each_with_index do |ex_data, index|
          exercise = find_or_create_exercise(ex_data)

          RoutineExercise.create!(
            routine: routine,
            exercise: exercise,
            day_number: ex_data["day_number"],
            day_name: ex_data["day_name"],
            sets: ex_data["sets"],
            reps: ex_data["reps"].to_s,
            rir: ex_data["rir"].to_s,
            rest_seconds: ex_data["rest_seconds"],
            warmup: ex_data["warmup"] || false,
            warmup_sets: ex_data["warmup_sets"],
            early_rpe: ex_data["early_rpe"],
            last_rpe: ex_data["last_rpe"],
            time_estimate: ex_data["time_estimate"],
            substitutions: ex_data["substitutions"],
            instructions: ex_data["instructions"],
            order_index: index
          )
        end
      end

      # Create DietaryPlan if suggested
      if data["dietary_plan"]
        dietary_plan = DietaryPlan.create!(
          name: data["dietary_plan"]["name"],
          description: data["dietary_plan"]["description"],
          calories_target: data["dietary_plan"]["calories_target"],
          protein_target: data["dietary_plan"]["protein_target"]
        )

        # Assign to user if present
        if user
          UserDietaryPlan.create!(
            user: user,
            dietary_plan: dietary_plan,
            start_date: Date.current,
            end_date: Date.current + (program&.duration_weeks || 8).weeks
          )
        end
      end

      # Update conversation status
      conversation.update!(status: "completed", program: program)

      program || Routine.where(user: user).last
    end
  end

  private

  # RAG: embed query and retrieve relevant book chunks
  def retrieve_context(query)
    query_embedding = @embedding_service.embed(query)
    return "No book knowledge available." unless query_embedding

    chunks = BookChunk.search(query_embedding, limit: 10)

    if chunks.any?
      chunks.map.with_index do |chunk, i|
        "[Source #{i + 1} - #{chunk.book.title}, p.#{chunk.page_number}]\n#{chunk.content}"
      end.join("\n\n")
    else
      "No relevant book knowledge found for this query."
    end
  end

  def build_client_profile(user)
    return "No specific client selected. Generate a general template." unless user

    <<~PROFILE
      CLIENT PROFILE:
      - Name: #{user.name}
      - Category: #{user.category}
      - Status: #{user.status}
      - Current Weight: #{user.latest_weight || 'Not logged'}
      - Weight Trend (7d): #{user.weight_trend || 'N/A'}
      - Workout Compliance: #{user.calculate_workout_compliance_score}%
      - Diet Adherence: #{user.calculate_diet_adherence_score}%
      - Current Programs: #{user.programs.map(&:name).join(', ').presence || 'None'}
      - Target Workouts/Week: #{user.target_workouts_per_week}
    PROFILE
  end

  def build_system_prompt(mode)
    <<~SYSTEM
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
    SYSTEM
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

      For exercises, if an exercise already exists in the database, use its exact name.
      If you need to suggest a new exercise, provide a descriptive name and muscle_group.
      Set "existing_exercise_id" to null for new exercises.

      REQUIRED JSON STRUCTURE:
      #{json_schema}

      Return ONLY the JSON. No explanations, no markdown fences.
    PROMPT
  end

  def generation_json_schema(mode)
    <<~JSON
      {
        "program": {
          "name": "string",
          "description": "string (detailed program overview)",
          "duration_weeks": integer
        },
        "routines": [
          {
            "name": "string (e.g. 'Upper Body Push')",
            "description": "string",
            "duration_weeks": integer,
            "exercises": [
              {
                "name": "string (exact name if existing, descriptive if new)",
                "muscle_group": "string (e.g. 'Chest', 'Back', 'Legs')",
                "existing_exercise_id": integer_or_null,
                "day_number": integer,
                "day_name": "string (e.g. 'Monday')",
                "sets": integer,
                "warmup_sets": "string (e.g. '1-2' or '0')",
                "reps": "string (e.g. '8-10' or '12')",
                "early_rpe": "string (e.g. '~7')",
                "last_rpe": "string (e.g. '~8')",
                "rest_seconds": integer,
                "time_estimate": "string (e.g. '8-10 min')",
                "substitutions": ["string", "string"],
                "warmup": boolean,
                "instructions": "string"
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

  # Find existing exercise by name or create a new one
  def find_or_create_exercise(ex_data)
    if ex_data["existing_exercise_id"]
      Exercise.find_by(id: ex_data["existing_exercise_id"]) ||
        Exercise.find_or_create_by!(name: ex_data["name"]) do |e|
          e.muscle_group = ex_data["muscle_group"]
        end
    else
      Exercise.find_or_create_by!(name: ex_data["name"]) do |e|
        e.muscle_group = ex_data["muscle_group"]
      end
    end
  end

  def call_gemini(system_prompt, user_prompt, history: [])
    uri = URI("#{@base_url}?key=#{@api_key}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

    # Build contents array with optional history
    contents = []

    # Add conversation history for refinements
    history.each do |msg|
      contents << {
        role: msg[:role] == "assistant" ? "model" : "user",
        parts: [ { text: msg[:content] } ]
      }
    end

    # Add current user prompt
    contents << { role: "user", parts: [ { text: user_prompt } ] }

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = {
      system_instruction: { parts: [ { text: system_prompt } ] },
      contents: contents,
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 8192
      }
    }.to_json

    response = http.request(request)

    if response.code == "200"
      json = JSON.parse(response.body)
      json.dig("candidates", 0, "content", "parts", 0, "text")
    else
      Rails.logger.error("Gemini API Error: #{response.code} - #{response.body}")
      raise "Gemini API error: #{response.code}"
    end
  end

  def parse_json_response(text)
    return {} unless text

    # 1. Attempt to parse clean text first
    begin
      return JSON.parse(text)
    rescue JSON::ParserError
      # Continue to extraction strategies
    end

    # 2. Extract from markdown code fences
    if text.include?("```json")
      match = text.match(/```json\s*(.*?)\s*```/m)
      return JSON.parse(match[1]) if match
    end

    # 3. Handle generic fences
    if text.include?("```")
      match = text.match(/```\s*(.*?)\s*```/m)
      return JSON.parse(match[1]) if match
    end

    # 4. Fallback: Find first '{' and last '}'
    # This handles "Here is your JSON: { ... } Hope it helps"
    first_brace = text.index('{')
    last_brace = text.rindex('}')

    if first_brace && last_brace && last_brace > first_brace
      json_candidate = text[first_brace..last_brace]
      begin
        return JSON.parse(json_candidate)
      rescue JSON::ParserError
        Rails.logger.error("AiCoachService JSON extract failed on candidate: #{json_candidate.first(100)}...")
      end
    end

    Rails.logger.error("AiCoachService failed to parse response: #{text.first(100)}...")
    {}
  rescue JSON::ParserError => e
    Rails.logger.error("AiCoachService JSON parse error: #{e.message}")
    Rails.logger.error("Raw response: #{text}")
    {}
  end
end
