require "rails_helper"

RSpec.describe Remarkable::CustomRenderer do
  let(:renderer) { described_class.new }
  let(:guest_renderer) { described_class.new(guest: true) }
  let(:non_guest_renderer) { described_class.new(guest: false) }

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

  describe "#image" do
    context "YouTube video detection" do
      it "detects 11-character alphanumeric video ID" do
        html = non_guest_renderer.image("dQw4w9WgXcQ", "", "")
        expect(html).to include("youtube.com/embed/dQw4w9WgXcQ")
        expect(html).to include('class="ratio ratio-16x9')
      end

      it "handles video ID with hyphens and underscores" do
        html = non_guest_renderer.image("dQw4w9W-XcQ", "", "")
        expect(html).to include("youtube.com/embed/dQw4w9W-XcQ")
      end

      it "renders full-width video without centering classes" do
        html = non_guest_renderer.image("dQw4w9WgXcQ", "", "")
        expect(html).to include('ratio ratio-16x9')
        expect(html).not_to include('col-')
        expect(html).not_to include('offset-')
      end

      it "renders video with centered caption" do
        html = non_guest_renderer.image("dQw4w9WgXcQ", "c", "Amazing video")
        expect(html).to include("youtube.com/embed/dQw4w9WgXcQ")
        expect(html).to include("Amazing video")
        expect(html).to include("figure-caption text-center")
        expect(html).to include('class="figure w-100"')
      end

      it "renders video with left-aligned caption" do
        html = non_guest_renderer.image("dQw4w9WgXcQ", "C", "Amazing video")
        expect(html).to include("youtube.com/embed/dQw4w9WgXcQ")
        expect(html).to include("Amazing video")
        expect(html).to include("figure-caption px-2")
        expect(html).not_to include("text-center")
      end

      it "renders video with custom sizing" do
        html = non_guest_renderer.image("dQw4w9WgXcQ", "8,6", "")
        expect(html).to include("youtube.com/embed/dQw4w9WgXcQ")
        expect(html).to include('class="row"')
        expect(html).to include('col-8')
        expect(html).to include('offset-2')
      end

      it "renders video with custom sizing and caption" do
        html = non_guest_renderer.image("dQw4w9WgXcQ", "8,6,C", "Test caption")
        expect(html).to include("youtube.com/embed/dQw4w9WgXcQ")
        expect(html).to include("Test caption")
        expect(html).to include('class="row"')
        expect(html).to include('col-8')
        expect(html).to include('figure class="figure w-100"')
      end

      it "does not show caption if alt text is blank" do
        html = non_guest_renderer.image("dQw4w9WgXcQ", "c", "")
        expect(html).to include("youtube.com/embed/dQw4w9WgXcQ")
        expect(html).not_to include("figcaption")
      end

      it "includes allowfullscreen attribute" do
        html = non_guest_renderer.image("dQw4w9WgXcQ", "", "")
        expect(html).to include("allowfullscreen")
      end
    end

    context "Active Storage image detection" do
      it "detects numeric image ID" do
        image = create(:image)
        html = non_guest_renderer.image(image.id.to_s, "", "")
        expect(html).to include("img")
        expect(html).not_to include("youtube")
      end

      it "rejects non-existent image ID with error for non-guests" do
        html = non_guest_renderer.image("99999", "", "")
        expect(html).to include("alert-danger")
        expect(html).to include("Image not found")
      end

      it "returns empty string for non-existent image ID for guests" do
        html = guest_renderer.image("99999", "", "")
        expect(html).to eq("")
      end
    end

    context "invalid media ID" do
      it "rejects 12-character string" do
        html = non_guest_renderer.image("dQw4w9WgXcQx", "", "")
        expect(html).to include("alert-danger")
        expect(html).to include("Invalid media ID")
      end

      it "rejects 10-character string" do
        html = non_guest_renderer.image("dQw4w9WgXc", "", "")
        expect(html).to include("alert-danger")
        expect(html).to include("Invalid media ID")
      end

      it "rejects special characters" do
        html = non_guest_renderer.image("dQw4w9W@XcQ", "", "")
        expect(html).to include("alert-danger")
        expect(html).to include("Invalid media ID")
      end

      it "rejects empty string" do
        html = non_guest_renderer.image("", "", "")
        expect(html).to include("alert-danger")
        expect(html).to include("Invalid media ID")
      end

      it "returns empty string for invalid ID for guests" do
        html = guest_renderer.image("invalid", "", "")
        expect(html).to eq("")
      end
    end

    context "invalid breakpoint syntax" do
      it "shows error for non-guests with invalid YouTube video breakpoints" do
        html = non_guest_renderer.image("dQw4w9WgXcQ", "invalid", "")
        expect(html).to include("alert-danger")
        expect(html).to include("Invalid breakpoint syntax")
      end

      it "returns empty string for guests with invalid breakpoints" do
        html = guest_renderer.image("dQw4w9WgXcQ", "invalid", "")
        expect(html).to eq("")
      end
    end
  end
end
