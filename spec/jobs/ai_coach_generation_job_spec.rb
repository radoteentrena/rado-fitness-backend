require "rails_helper"

RSpec.describe AiCoachGenerationJob, type: :job do
  let(:conversation) do
    AiConversation.create!(objectives: "4 días/semana Upper/Lower", title: "Generando…", status: "generating")
  end

  let(:structured_data) do
    {
      "program"  => { "name" => "Plan Test", "description" => "Bloque de prueba", "duration_weeks" => 8 },
      "routines" => []
    }
  end

  it "fills the conversation, marks it ready, and broadcasts the rendered result" do
    allow_any_instance_of(AiCoachService).to receive(:generate_program)
      .and_return({ conversation: conversation, structured_data: structured_data })

    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
      .with(conversation, hash_including(target: "ai_coach_result", partial: "admin/ai_coach/result"))
      .and_call_original

    described_class.perform_now(conversation.id, mode: "program")

    expect(conversation.reload.status).to eq("ready")
  end

  it "marks the conversation failed and broadcasts an error when the AI returns no data" do
    allow_any_instance_of(AiCoachService).to receive(:generate_program)
      .and_return({ conversation: conversation, structured_data: {} })

    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
      .with(conversation, hash_including(partial: "admin/ai_coach/generation_error"))
      .and_call_original

    described_class.perform_now(conversation.id)

    expect(conversation.reload.status).to eq("failed")
  end

  it "marks the conversation failed when generation raises" do
    allow_any_instance_of(AiCoachService).to receive(:generate_program).and_raise("boom")

    described_class.perform_now(conversation.id)

    expect(conversation.reload.status).to eq("failed")
  end
end
