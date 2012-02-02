require 'assert'

require 'xmlss/writer'
require 'xmlss/workbook'

module Xmlss

  class BasicTests < Assert::Context
    desc "UndiesWriter"
    setup do
      @w = Writer.new
    end
    subject { @w }

    should have_class_methods :attributes, :classify, :coerce
    should have_readers :style_markup, :element_markup, :flush

    should have_instance_methods :style, :alignment, :borders, :border
    should have_instance_methods :font, :interior, :number_format, :protection

    should have_instance_methods :workbook, :worksheet, :column, :row, :data

    should have_instance_methods :type, :index, :style_id, :formula, :href
    should have_instance_methods :merge_across, :merge_down, :height
    should have_instance_methods :auto_fit_height, :hidden, :width
    should have_instance_methods :auto_fit_width, :name

    should "return itself when flushed" do
      assert_equal subject, subject.flush
    end

  end

  class HelpersTests < BasicTests

    should "coerce certain values for xml output" do
      assert_equal 1, Writer.coerce(true)
      assert_nil Writer.coerce(false)
      assert_nil Writer.coerce("")
      assert_equal "hi", Writer.coerce("hi")
      assert_equal 1, Writer.coerce(1)
    end

    should "classify underscored string" do
      assert_equal "Hi", Writer.classify("Hi")
      assert_equal "Hi", Writer.classify("hi")
      assert_equal "Hithere", Writer.classify("HiThere")
      assert_equal "Hithere", Writer.classify("hithere")
      assert_equal "HiThere", Writer.classify("Hi_There")
      assert_equal "HiThere", Writer.classify("Hi_there")
      assert_equal "HiThere", Writer.classify("hi_there")
    end

    should "convert a list of attributes for xml output" do
      class Thing
        def keys; [:thing, :other, 'some', 'hi', :hi_there]; end

        def thing;    true;   end
        def other;    false;  end
        def some;     "";     end
        def hi;       :there; end
        def hi_there; "you";  end
      end
      thing = Thing.new
      exp = {
        "ss:Hi" => "there",
        "ss:HiThere" => "you",
        "ss:Thing" => "1"
      }

      assert_equal exp, Writer.attributes(thing, thing.keys)
    end

  end

  class StyleWritingTests < BasicTests
    desc "writing style markup"

    should "write alignment markup" do
      subject.alignment(Xmlss::Style::Alignment.new({
        :wrap_text => true,
        :horizontal => :center,
        :vertical => :bottom,
        :rotate => 90
      }))
      subject.flush

      assert_equal(
        "<Alignment ss:Horizontal=\"Center\" ss:Rotate=\"90\" ss:Vertical=\"Bottom\" ss:WrapText=\"1\" />",
        subject.style_markup
      )
    end

    should "write border markup" do
      subject.border(Xmlss::Style::Border.new({
        :color => '#FF0000',
        :position => :top,
        :weight => :thick,
        :line_style => :dot
      }))
      subject.flush

      assert_equal(
        "<Border ss:Color=\"#FF0000\" ss:LineStyle=\"Dot\" ss:Position=\"Top\" ss:Weight=\"3\" />",
        subject.style_markup
      )
    end

    should "write border collection markup" do
      subject.borders {
        subject.border(Xmlss::Style::Border.new({
          :color => '#FF0000',
          :position => :top
        }))
        subject.border(Xmlss::Style::Border.new({
          :position => :left
        }))
      }
      subject.flush

      assert_equal(
        "<Borders><Border ss:Color=\"#FF0000\" ss:LineStyle=\"Continuous\" ss:Position=\"Top\" ss:Weight=\"1\" /><Border ss:LineStyle=\"Continuous\" ss:Position=\"Left\" ss:Weight=\"1\" /></Borders>",
        subject.style_markup
      )
    end

    should "write font markup" do
      subject.font(Xmlss::Style::Font.new({
        :bold => true,
        :color => '#FF0000',
        :italic => true,
        :size => 10,
        :strike_through => true,
        :underline => :single,
        :alignment => :superscript,
        :name => 'Verdana'
      }))
      subject.flush

      assert_equal(
        "<Font ss:Bold=\"1\" ss:Color=\"#FF0000\" ss:FontName=\"Verdana\" ss:Italic=\"1\" ss:Size=\"10\" ss:StrikeThrough=\"1\" ss:Underline=\"Single\" ss:VerticalAlign=\"Superscript\" />",
        subject.style_markup
      )
    end

    should "write interior markup" do
      subject.interior(Xmlss::Style::Interior.new({
        :color => "#000000",
        :pattern => :solid,
        :pattern_color => "#FF0000"
      }))
      subject.flush

      assert_equal(
        "<Interior ss:Color=\"#000000\" ss:Pattern=\"Solid\" ss:PatternColor=\"#FF0000\" />",
        subject.style_markup
      )
    end

    should "write number format markup" do
      subject.number_format(Xmlss::Style::NumberFormat.new("General"))
      subject.flush

      assert_equal(
        "<NumberFormat ss:Format=\"General\" />",
        subject.style_markup
      )
    end

    should "write protection markup" do
      subject.protection(Xmlss::Style::Protection.new(true))
      subject.flush

      assert_equal(
        "<Protection ss:Protect=\"1\" />",
        subject.style_markup
      )
    end

    should "write full style markup" do
      subject.style(Xmlss::Style::Base.new(:write_markup_test)) {
        subject.alignment(Xmlss::Style::Alignment.new({
          :horizontal => :left,
          :vertical => :center,
          :wrap_text => true
        }))
        subject.borders {
          subject.border(Xmlss::Style::Border.new({:position => :left}))
          subject.border(Xmlss::Style::Border.new({:position => :right}))
        }
        subject.font(Xmlss::Style::Font.new({:bold => true}))
        subject.interior(Xmlss::Style::Interior.new({:color => "#000000"}))
        subject.number_format(Xmlss::Style::NumberFormat.new("General"))
        subject.protection(Xmlss::Style::Protection.new(true))
      }
      subject.flush

      assert_equal(
        "<Style ss:ID=\"write_markup_test\"><Alignment ss:Horizontal=\"Left\" ss:Vertical=\"Center\" ss:WrapText=\"1\" /><Borders><Border ss:LineStyle=\"Continuous\" ss:Position=\"Left\" ss:Weight=\"1\" /><Border ss:LineStyle=\"Continuous\" ss:Position=\"Right\" ss:Weight=\"1\" /></Borders><Font ss:Bold=\"1\" /><Interior ss:Color=\"#000000\" /><NumberFormat ss:Format=\"General\" /><Protection ss:Protect=\"1\" /></Style>",
        subject.style_markup
      )
    end

  end


  class WorksheetWritingTests < BasicTests
    desc "writing worksheet markup"

    should "write data markup" do
      subject.data(Xmlss::Element::Data.new("some data"))
      subject.flush

      assert_equal(
        "<Data ss:Type=\"String\">some data</Data>",
        subject.element_markup
      )
    end

    should "write data markup w/ \\n line breaks" do
      subject.data(Xmlss::Element::Data.new("line\nbreak", :type => :string))
      subject.flush

      assert_equal "<Data ss:Type=\"String\">line#{Writer::LB}break</Data>", subject.element_markup
    end

    should "write data markup w/ \\r line breaks" do
      subject.data(Xmlss::Element::Data.new("line\rbreak", :type => :string))
      subject.flush

      assert_equal "<Data ss:Type=\"String\">line#{Writer::LB}break</Data>", subject.element_markup
    end

    should "write data markup w/ \\r\\n line breaks" do
      subject.data(Xmlss::Element::Data.new("line\r\nbreak", :type => :string))
      subject.flush

      assert_equal "<Data ss:Type=\"String\">line#{Writer::LB}break</Data>", subject.element_markup
    end

    should "write data markup w/ \\n\\r line breaks" do
      subject.data(Xmlss::Element::Data.new("line\n\rbreak", :type => :string))
      subject.flush

      assert_equal "<Data ss:Type=\"String\">line#{Writer::LB}break</Data>", subject.element_markup
    end

    should "write data markup w/ line breaks and leading space" do
      subject.data(Xmlss::Element::Data.new(%s{
Should
  honor
    this}, :type => :string))
      subject.flush

      assert_equal(
        "<Data ss:Type=\"String\">#{Writer::LB}Should#{Writer::LB}  honor#{Writer::LB}    this</Data>",
        subject.element_markup
      )
    end

    should "write data markup w/ escaped values" do
      subject.data(Xmlss::Element::Data.new("some\n&<>'\"/\ndata"))
      subject.flush

      assert_equal(
        "<Data ss:Type=\"String\">some&#13;&#10;&amp;&lt;&gt;&#x27;&quot;&#x2F;&#13;&#10;data</Data>",
        subject.element_markup
      )
    end

    should "write cell markup" do
      subject.cell(Xmlss::Element::Cell.new({:index => 2})) {
        subject.data(Xmlss::Element::Data.new("some data"))
      }
      subject.flush

      assert_equal(
        "<Cell ss:Index=\"2\"><Data ss:Type=\"String\">some data</Data></Cell>",
        subject.element_markup
      )
    end

    should "write attribute markup" do
      subject.column(Xmlss::Element::Column.new(:width => 120)) {
        subject.style_id 'narrowcolumn'
      }
      subject.row(Xmlss::Element::Row.new(:hidden => true)) {
        subject.height 120
        subject.style_id 'awesome'

        subject.cell(Xmlss::Element::Cell.new(:index => 2)) {
          subject.href "http://www.google.com"

          subject.data(Xmlss::Element::Data.new("100")) {
            subject.type :number
          }
        }
      }
      subject.flush

      assert_equal(
        "<Column ss:StyleID=\"narrowcolumn\" ss:Width=\"120\"></Column><Row ss:Height=\"120\" ss:Hidden=\"1\" ss:StyleID=\"awesome\"><Cell ss:HRef=\"http://www.google.com\" ss:Index=\"2\"><Data ss:Type=\"Number\">100</Data></Cell></Row>",
        subject.element_markup
      )
    end

    should "write column markup" do
      subject.column(Xmlss::Element::Column.new({:hidden => true}))
      subject.flush

      assert_equal(
        "<Column ss:Hidden=\"1\" />",
        subject.element_markup
      )
    end

    should "write worksheet markup" do
      subject.worksheet(Xmlss::Element::Worksheet.new('test')) {
        subject.row(Xmlss::Element::Row.new({:hidden => true})) {
          subject.cell(Xmlss::Element::Cell.new({:index => 2})) {
            subject.data(Xmlss::Element::Data.new("some data"))
          }
        }
      }
      subject.flush

      assert_equal(
        "<Worksheet ss:Name=\"test\"><Table><Row ss:Hidden=\"1\"><Cell ss:Index=\"2\"><Data ss:Type=\"String\">some data</Data></Cell></Row></Table></Worksheet>",
        subject.element_markup
      )
    end

    should "return workbook markup" do
      subject.style(Xmlss::Style::Base.new(:some_font)) {
        subject.font(Xmlss::Style::Font.new({:bold => true}))
      }

      subject.style(Xmlss::Style::Base.new(:some_numformat)) {
        subject.number_format(Xmlss::Style::NumberFormat.new("General"))
      }

      subject.worksheet(Xmlss::Element::Worksheet.new('test')) {
        subject.row(Xmlss::Element::Row.new({:hidden => true})) {
          subject.cell(Xmlss::Element::Cell.new({:index => 2})) {
            subject.data(Xmlss::Element::Data.new("some data"))
          }
        }
      }

      subject.flush

      assert_equal(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Workbook xmlns=\"urn:schemas-microsoft-com:office:spreadsheet\" xmlns:ss=\"urn:schemas-microsoft-com:office:spreadsheet\"><Styles><Style ss:ID=\"some_font\"><Font ss:Bold=\"1\" /></Style><Style ss:ID=\"some_numformat\"><NumberFormat ss:Format=\"General\" /></Style></Styles><Worksheet ss:Name=\"test\"><Table><Row ss:Hidden=\"1\"><Cell ss:Index=\"2\"><Data ss:Type=\"String\">some data</Data></Cell></Row></Table></Worksheet></Workbook>",
        subject.workbook
      )
    end

    should "return pretty workbook markup" do
      writer = Writer.new(:pp => 2)
      writer.style(Xmlss::Style::Base.new(:some_font)) {
        writer.font(Xmlss::Style::Font.new({:bold => true}))
      }

      writer.style(Xmlss::Style::Base.new(:some_numformat)) {
        writer.number_format(Xmlss::Style::NumberFormat.new("General"))
      }

      writer.worksheet(Xmlss::Element::Worksheet.new('test')) {
        writer.row(Xmlss::Element::Row.new({:hidden => true})) {
          writer.cell(Xmlss::Element::Cell.new({:index => 2})) {
            writer.data(Xmlss::Element::Data.new("some data"))
          }
        }
      }

      writer.flush

      assert_equal(
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Workbook xmlns=\"urn:schemas-microsoft-com:office:spreadsheet\" xmlns:ss=\"urn:schemas-microsoft-com:office:spreadsheet\">\n  <Styles>\n    <Style ss:ID=\"some_font\">\n      <Font ss:Bold=\"1\" />\n    </Style>\n    <Style ss:ID=\"some_numformat\">\n      <NumberFormat ss:Format=\"General\" />\n    </Style>\n  </Styles>\n  <Worksheet ss:Name=\"test\">\n    <Table>\n      <Row ss:Hidden=\"1\">\n        <Cell ss:Index=\"2\">\n          <Data ss:Type=\"String\">some data</Data>\n        </Cell>\n      </Row>\n    </Table>\n  </Worksheet>\n</Workbook>",
        writer.workbook
      )
    end



  end

end
