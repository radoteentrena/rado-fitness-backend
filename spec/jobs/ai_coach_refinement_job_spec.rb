require "rails_helper"

RSpec.describe AiCoachRefinementJob, type: :job do
  let(:conversation) do
    AiConversation.create!(
      objectives:     "4 días/semana Upper/Lower",
      title:          "Plan Test",
      status:         "ready",
      generated_data: { "routines" => [] }
    )
  end

  let(:structured_data) do
    { "program" => { "name" => "Plan Test v2", "duration_weeks" => 8 }, "routines" => [] }
  end

  it "broadcasts the refined result" do
    allow_any_instance_of(AiCoachService).to receive(:refine)
      .and_return({ conversation: conversation, structured_data: structured_data })

    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
      .with(conversation, hash_including(target: "ai_coach_result", partial: "admin/ai_coach/result"))
      .and_call_original

    described_class.perform_now(conversation.id, "agregá más espalda")
  end

  it "broadcasts an error when refinement raises" do
    allow_any_instance_of(AiCoachService).to receive(:refine).and_raise("boom")

    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
      .with(conversation, hash_including(partial: "admin/ai_coach/generation_error"))
      .and_call_original

    described_class.perform_now(conversation.id, "cambio")
  end
end
