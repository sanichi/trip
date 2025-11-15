require "rails_helper"

RSpec.describe Remarkable::CustomRenderer do
  let(:renderer) { described_class.new }

  describe "#parse_breakpoints" do
    context "with blank title" do
      it "returns default breakpoints with no caption" do
        result = renderer.send(:parse_breakpoints, nil)
        expect(result).to eq({
          breakpoints: { xs: 12 },
          show_caption: false,
          center_caption: false
        })
      end

      it "handles empty string" do
        result = renderer.send(:parse_breakpoints, "")
        expect(result).to eq({
          breakpoints: { xs: 12 },
          show_caption: false,
          center_caption: false
        })
      end
    end

    context "with valid breakpoints" do
      it "parses single breakpoint" do
        result = renderer.send(:parse_breakpoints, "12")
        expect(result[:breakpoints]).to eq({ xs: 12 })
        expect(result[:show_caption]).to be false
      end

      it "parses two breakpoints" do
        result = renderer.send(:parse_breakpoints, "12,10")
        expect(result[:breakpoints]).to eq({ xs: 12, sm: 10 })
        expect(result[:show_caption]).to be false
      end

      it "parses four breakpoints" do
        result = renderer.send(:parse_breakpoints, "12,10,8,6")
        expect(result[:breakpoints]).to eq({ xs: 12, sm: 10, md: 8, lg: 6 })
      end

      it "parses six breakpoints" do
        result = renderer.send(:parse_breakpoints, "12,11,10,9,8,6")
        expect(result[:breakpoints]).to eq({ xs: 12, sm: 11, md: 10, lg: 9, xl: 8, xx: 6 })
      end

      it "handles whitespace around values" do
        result = renderer.send(:parse_breakpoints, "12 , 10 , 8")
        expect(result[:breakpoints]).to eq({ xs: 12, sm: 10, md: 8 })
      end

      it "accepts values from 1 to 12" do
        result = renderer.send(:parse_breakpoints, "1,6,12")
        expect(result[:breakpoints]).to eq({ xs: 1, sm: 6, md: 12 })
      end
    end

    context "with invalid breakpoints" do
      it "rejects non-numeric values" do
        result = renderer.send(:parse_breakpoints, "12,abc")
        expect(result).to be_nil
      end

      it "rejects values greater than 12" do
        result = renderer.send(:parse_breakpoints, "13,10")
        expect(result).to be_nil
      end

      it "rejects values less than 1" do
        result = renderer.send(:parse_breakpoints, "0,10")
        expect(result).to be_nil
      end

      it "rejects negative values" do
        result = renderer.send(:parse_breakpoints, "-1,10")
        expect(result).to be_nil
      end

      it "rejects more than 6 breakpoints" do
        result = renderer.send(:parse_breakpoints, "12,11,10,9,8,7,6")
        expect(result).to be_nil
      end

      it "rejects empty values" do
        result = renderer.send(:parse_breakpoints, "12,,10")
        expect(result).to be_nil
      end
    end

    context "with caption flag only" do
      it "recognizes lowercase 'c' for centered caption" do
        result = renderer.send(:parse_breakpoints, "c")
        expect(result).to eq({
          breakpoints: { xs: 12 },
          show_caption: true,
          center_caption: true
        })
      end

      it "recognizes uppercase 'C' for left-aligned caption" do
        result = renderer.send(:parse_breakpoints, "C")
        expect(result).to eq({
          breakpoints: { xs: 12 },
          show_caption: true,
          center_caption: false
        })
      end
    end

    context "with breakpoints and caption flag" do
      it "parses breakpoints with lowercase 'c'" do
        result = renderer.send(:parse_breakpoints, "12,10,8,6,c")
        expect(result[:breakpoints]).to eq({ xs: 12, sm: 10, md: 8, lg: 6 })
        expect(result[:show_caption]).to be true
        expect(result[:center_caption]).to be true
      end

      it "parses breakpoints with uppercase 'C'" do
        result = renderer.send(:parse_breakpoints, "12,10,8,6,C")
        expect(result[:breakpoints]).to eq({ xs: 12, sm: 10, md: 8, lg: 6 })
        expect(result[:show_caption]).to be true
        expect(result[:center_caption]).to be false
      end

      it "parses single breakpoint with caption" do
        result = renderer.send(:parse_breakpoints, "12,c")
        expect(result[:breakpoints]).to eq({ xs: 12 })
        expect(result[:show_caption]).to be true
        expect(result[:center_caption]).to be true
      end

      it "is case-sensitive (rejects mixed case)" do
        result = renderer.send(:parse_breakpoints, "12,10,8,Cc")
        expect(result).to be_nil
      end
    end

    context "with invalid caption combinations" do
      it "rejects non-numeric value before caption flag" do
        result = renderer.send(:parse_breakpoints, "abc,c")
        expect(result).to be_nil
      end

      it "rejects invalid breakpoint value with caption flag" do
        result = renderer.send(:parse_breakpoints, "13,c")
        expect(result).to be_nil
      end

      it "rejects 'c' in middle of values" do
        result = renderer.send(:parse_breakpoints, "12,c,10")
        expect(result).to be_nil
      end
    end
  end
end
