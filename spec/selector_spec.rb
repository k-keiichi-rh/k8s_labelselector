# frozen_string_literal: true

RSpec.describe LabelSelector::Selector do
  def expect_match(label_selector, input_labels)
    ls = LabelSelector.parse(label_selector)
    expect(ls).not_to be nil
    expect(ls.match?(input_labels)).to be true
  end

  def expect_nomatch(label_selector, input_labels)
    ls = LabelSelector.parse(label_selector)
    expect(ls).not_to be nil
    expect(ls.match?(input_labels)).to be false
  end

  describe ".match?" do
    context "when matching input labels with a rount-robin" do 
      let(:labels) { {"foo": "bar", "hoge": "fuga"} }
      it "should return true" do
        expect_match("foo=bar", labels)
        expect_match("hoge=fuga", labels)
        expect_match("foo=bar,hoge=fuga", labels)
      end
      it "should return true" do
        expect_nomatch("foo=fuga", labels)
        expect_nomatch("hoge=bar", labels)
        expect_nomatch("foo=bar,foobar=bar,hoge=fuga", labels)
      end
    end
    context "when matching input labels" do
      it "should return true" do
        expect_match("", {"x": "a"})
        expect_match("x=a", {"x": "a"})
        expect_match("x=a,y=b", {"x": "a", "y": "b"})
        expect_match("x!=a,y!=b", {"x": "b", "y": "a"})
        expect_match("notin=in", {"notin": "in"})
        expect_match("x", {"x": "a"})
        expect_match("!x", {"y": "b"})
      end
      it "should return false" do
        expect_nomatch("x=a", {})
        expect_nomatch("x=a", {"x": "b"})
        expect_nomatch("x=a,y=b", {"x": "a", "y": "a"})
        expect_nomatch("x!=a,y!=b", {"x": "a", "y": "b"})
        expect_nomatch("x", {"y": "b"})
        expect_nomatch("!x", {"x": "a"})
      end
    end
  end

  describe ".parse" do
    context "when parsing valid label selector string" do
      it "should return requirement objects" do
        expect(LabelSelector.parse("")).not_to be nil
        expect(LabelSelector.parse("x!=a,y=b")).not_to be nil
        expect(LabelSelector.parse("x=a,y=b,z=c")).not_to be nil
        expect(LabelSelector.parse("x")).not_to be nil
        expect(LabelSelector.parse("x=")).not_to be nil
        expect(LabelSelector.parse("x=,z= ")).not_to be nil
        expect(LabelSelector.parse("x= ,z= ")).not_to be nil
        expect(LabelSelector.parse("!x")).not_to be nil
      end

      it "should do deteministic parse" do
        s1 = LabelSelector.parse("x=a,a=x")
        s2 = LabelSelector.parse("a=x,x=a")
        expect(s1).not_to be nil
        expect(s2).not_to be nil
        expect(s1.to_s == s2.to_s).to be true
      end
    end
    context "when parsing invalid label selector string" do
      it "should return nil" do
        expect(LabelSelector.parse("x=a||y=b")).to be nil
        expect(LabelSelector.parse("x==a==b")).to be nil
        expect(LabelSelector.parse("!x=a")).to be nil
      end
    end
  end
end

RSpec.describe LabelSelector::Requirement do
  describe ".match?" do
    describe "when the Requirement matches input labels" do
      context "with Equality-based restriction" do
        it "returns true" do
          expect(LabelSelector::Requirement.new("x", LabelSelector::EQUAL, ["a"]).match?({"x": "a"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::EQUAL, ["a"]).match?({"x": "a", "y": "b"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::DOUBLEEQUALS, ["a"]).match?({"x": "a"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::DOUBLEEQUALS, ["a"]).match?({"x": "a", "y": "b"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::NOTEQUAL, []).match?({"x": "b"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::NOTEQUAL, ["a"]).match?({"x": "b"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::NOTEQUAL, ["a"]).match?({"x": "b", "y": "a"})).to be true
        end
        it "returns false" do
          expect(LabelSelector::Requirement.new("x", LabelSelector::EQUAL, []).match?({"x": "b"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::EQUAL, ["a"]).match?({"x": "b"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::EQUAL, ["a"]).match?({"x": "b", "y": "a"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::DOUBLEEQUALS, []).match?({"x": "b"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::DOUBLEEQUALS, ["a"]).match?({"x": "b"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::DOUBLEEQUALS, ["a"]).match?({"x": "b", "y": "a"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::NOTEQUAL, ["a"]).match?({"x": "a"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::NOTEQUAL, ["a"]).match?({"x": "a", "y": "b"})).to be false
        end
      end
      context "with Set-based restriction" do
        it "returns true" do
          expect(LabelSelector::Requirement.new("x", LabelSelector::IN, ["a"]).match?({"x": "a"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::IN, ["a"]).match?({"x": "a", "y": "b"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::IN, ["a", "a1"]).match?({"x": "a"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::IN, ["a", "a1"]).match?({"x": "a", "y": "b"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::NOTIN, []).match?({"x": "b"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::NOTIN, ["a"]).match?({"x": "b"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::NOTIN, ["a"]).match?({"x": "b", "y": "a"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::NOTIN, ["a", "a1"]).match?({"x": "b"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::NOTIN, ["a", "a1"]).match?({"x": "b", "y": "a"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::EXISTS, []).match?({"x": "a"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::EXISTS, []).match?({"x": "a", "y": "b"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::DOESNOTEXISTS, []).match?({"y": "b"})).to be true
          expect(LabelSelector::Requirement.new("x", LabelSelector::DOESNOTEXISTS, []).match?({"y": "b", "y": "a"})).to be true
        end
        it "returns false" do
          expect(LabelSelector::Requirement.new("x", LabelSelector::IN, []).match?({"x": "b"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::IN, ["a"]).match?({"x": "b"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::IN, ["a"]).match?({"x": "b", "y": "a"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::IN, ["a", "a1"]).match?({"x": "b"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::IN, ["a", "a1"]).match?({"x": "b", "y": "a"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::NOTIN, ["a"]).match?({"x": "a"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::NOTIN, ["a"]).match?({"x": "a", "y": "b"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::NOTIN, ["a", "a1"]).match?({"x": "a"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::NOTIN, ["a", "a1"]).match?({"x": "a", "y": "b"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::EXISTS, []).match?({"y": "a"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::EXISTS, []).match?({"y": "a", "z": "b"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::DOESNOTEXISTS, []).match?({"x": "a"})).to be false
          expect(LabelSelector::Requirement.new("x", LabelSelector::DOESNOTEXISTS, []).match?({"x": "a", "y": "a"})).to be false
        end
      end
    end
  end
end
