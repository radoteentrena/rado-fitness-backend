require "rails_helper"

RSpec.describe Subscriptions::Pricing do
  describe ".base_price" do
    context "for Argentina" do
      it "returns ARS price for basic" do
        expect(described_class.base_price(:basic, argentina: true)).to eq(14_000)
      end

      it "returns ARS price for medium" do
        expect(described_class.base_price(:medium, argentina: true)).to eq(70_000)
      end

      it "returns ARS price for high_ticket" do
        expect(described_class.base_price(:high_ticket, argentina: true)).to eq(140_000)
      end
    end

    context "for international" do
      it "returns USD price for basic" do
        expect(described_class.base_price(:basic, argentina: false)).to eq(10)
      end

      it "returns USD price for medium" do
        expect(described_class.base_price(:medium, argentina: false)).to eq(50)
      end

      it "returns USD price for high_ticket" do
        expect(described_class.base_price(:high_ticket, argentina: false)).to eq(100)
      end
    end
  end

  describe ".effective_price" do
    it "applies no discount for one_time monthly" do
      expect(described_class.effective_price(:basic, :one_time, :monthly, argentina: true)).to eq(14_000)
    end

    it "applies no discount for recurring monthly" do
      expect(described_class.effective_price(:basic, :recurring, :monthly, argentina: true)).to eq(14_000)
    end

    it "applies 5% discount for recurring quarterly" do
      expect(described_class.effective_price(:basic, :recurring, :quarterly, argentina: true)).to eq(13_300)
    end

    it "applies 10% discount for recurring yearly" do
      expect(described_class.effective_price(:basic, :recurring, :yearly, argentina: true)).to eq(12_600)
    end
  end

  describe ".currency" do
    it "returns ARS for Argentina" do
      expect(described_class.currency(argentina: true)).to eq("ARS")
    end

    it "returns USD otherwise" do
      expect(described_class.currency(argentina: false)).to eq("USD")
    end
  end

  describe ".currency_symbol" do
    it "returns $ for Argentina" do
      expect(described_class.currency_symbol(argentina: true)).to eq("$")
    end

    it "returns US$ otherwise" do
      expect(described_class.currency_symbol(argentina: false)).to eq("US$")
    end
  end
end
