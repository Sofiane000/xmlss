require "assert"
require 'xmlss/element/column'

class Xmlss::Element::Column

  class UnitTests < Assert::Context
    desc "Xmlss::Element::Column"
    before { @c = Xmlss::Element::Column.new }
    subject { @c }

    should be_styled
    should have_class_method :writer
    should have_accessors :width, :auto_fit_width, :autofit, :hidden
    should have_readers   :autofit?, :hidden?

    should "know its writer hook" do
      assert_equal :column, subject.class.writer
    end

    should "set it's defaults" do
      assert_equal nil, subject.width
      assert_equal false, subject.auto_fit_width
      assert_equal false, subject.hidden
    end

    should "bark when setting non Numeric width" do
      assert_raises ArgumentError do
        Xmlss::Element::Column.new({:width => "do it"})
      end

      assert_nothing_raised do
        Xmlss::Element::Column.new({:width => 2})
      end

      assert_nothing_raised do
        Xmlss::Element::Column.new({:width => 3.5})
      end
    end

    should "nil out height values that are < 0" do
      assert_equal nil, Xmlss::Element::Column.new({:width => -1.2}).width
      assert_equal nil, Xmlss::Element::Column.new({:width => -1}).width
      assert_equal 0,   Xmlss::Element::Column.new({:width => 0}).width
      assert_equal 1.2, Xmlss::Element::Column.new({:width => 1.2}).width
    end

  end

end
