# frozen_string_literal: true

RSpec.describe LabelSelector::LabelSelectorParser do
  describe "when parsing valid label selector string" do
    let(:lsp) { LabelSelector::LabelSelectorParser.new }
    context "with delimiter checking" do
      it "should parse label selector string" do
        expect{ lsp.parse("\nkey") }.not_to raise_error
        expect{ lsp.parse("\r !key") }.not_to raise_error
        expect{ lsp.parse("key  in         (abc)") }.not_to raise_error
        expect{ lsp.parse("key  notin\n (abc)") }.not_to raise_error
        expect{ lsp.parse("key  notin   \t     (abc,def)") }.not_to raise_error
        expect{ lsp.parse("key in ( value1 , value2 )") }.not_to raise_error
      end
    end
    context "with value/key/operator validation" do
      it "should parse collectly" do
        expect{ lsp.parse("notin=in") }.not_to raise_error
        expect{ lsp.parse("x in ()") }.not_to raise_error
        expect{ lsp.parse("x in ( )") }.not_to raise_error
        expect{ lsp.parse("x in (x)") }.not_to raise_error
        expect{ lsp.parse("x in (x,)") }.not_to raise_error
        expect{ lsp.parse("x in (x,,y)") }.not_to raise_error
        expect{ lsp.parse("x in (x,notin,z,in)") }.not_to raise_error
        expect{ lsp.parse("x in (, y)") }.not_to raise_error
        expect{ lsp.parse("key = Aa0_-.") }.not_to raise_error
      end
      it "should not parse" do
        expect{ lsp.parse("key = a$b") }.to raise_error Parslet::ParseFailed
        expect{ lsp.parse("key = a:b") }.to raise_error Parslet::ParseFailed
        expect{ lsp.parse("(") }.to raise_error Parslet::ParseFailed
        expect{ lsp.parse("key(") }.to raise_error Parslet::ParseFailed
        expect{ lsp.parse("key (") }.to raise_error Parslet::ParseFailed
        expect{ lsp.parse("x nott in (y)") }.to raise_error Parslet::ParseFailed
        expect{ lsp.parse("x notin(") }.to raise_error Parslet::ParseFailed
        expect{ lsp.parse("x notin (x y)") }.to raise_error Parslet::ParseFailed
      end
    end
    context "with syntax checking for single requirement" do
      it "should parse collectly" do
        expect{ lsp.parse("") }.not_to raise_error
        expect{ lsp.parse("key") }.not_to raise_error
        expect{ lsp.parse("!key") }.not_to raise_error
        expect{ lsp.parse("key = value") }.not_to raise_error
        expect{ lsp.parse("key == value") }.not_to raise_error
        expect{ lsp.parse("key != value") }.not_to raise_error
        expect{ lsp.parse("key in ( )") }.not_to raise_error
        expect{ lsp.parse("key in ( value )") }.not_to raise_error
        expect{ lsp.parse("key in ( value1, value2 )") }.not_to raise_error
        expect{ lsp.parse("key notin ( )") }.not_to raise_error
        expect{ lsp.parse("key notin ( value )") }.not_to raise_error
        expect{ lsp.parse("key notin ( value1, value2 )") }.not_to raise_error
      end
      it "should not parse" do
        expect{ lsp.parse("!key = value") }.to raise_error Parslet::ParseFailed
        expect{ lsp.parse("key = (") }.to raise_error Parslet::ParseFailed
        expect{ lsp.parse("key = )") }.to raise_error Parslet::ParseFailed
      end
    end
    context "with syntax checking for multiple requirements" do
      it "should parse collectly" do
        expect{ lsp.parse("key = a, key in ( a , b, c)") }.not_to raise_error
        expect{ lsp.parse("key in (v,), key = v") }.not_to raise_error
        expect{ lsp.parse("key in (,), key notin (v)") }.not_to raise_error
        expect{ lsp.parse("key = v, key != A, key == v") }.not_to raise_error
        expect{ lsp.parse("") }.not_to raise_error
        expect{ lsp.parse("") }.not_to raise_error
        expect{ lsp.parse("x notin (abc,,def),bar,z in (),w") }.not_to raise_error
        expect{ lsp.parse("x=a,y!=b") }.not_to raise_error
        expect{ lsp.parse("x=a,y!=b,z in (h,i,j)") }.not_to raise_error
      end
      it "should not parse" do
        expect{ lsp.parse("!key = value") }.to raise_error Parslet::ParseFailed
        expect{ lsp.parse("!key = value, key = b") }.to raise_error Parslet::ParseFailed
        expect{ lsp.parse("key notin ( value ),") }.to raise_error Parslet::ParseFailed
        expect{ lsp.parse("x notin (x y)b notin ()") }.to raise_error Parslet::ParseFailed
        expect{ lsp.parse(",x,y") }.to raise_error Parslet::ParseFailed
        expect{ lsp.parse("x,,y") }.to raise_error Parslet::ParseFailed
        expect{ lsp.parse("x=||y=b") }.to raise_error Parslet::ParseFailed
      end
    end
  end
end

RSpec.describe LabelSelector::LabelSelectorTransform do
  describe "when transforming by Parslet Transform" do
    let(:lsp) { LabelSelector::LabelSelectorParser.new }
    let(:lst) { LabelSelector::LabelSelectorTransform.new }
    it "should generate a single Requirement object" do
      expect(lst.apply(lsp.parse(""))[0].to_s).to eq("")
      expect(lst.apply(lsp.parse("x=y"))[0].to_s).to eq("x=y")
      expect(lst.apply(lsp.parse("x==y"))[0].to_s).to eq("x==y")
      expect(lst.apply(lsp.parse("x!=y"))[0].to_s).to eq("x!=y")
      expect(lst.apply(lsp.parse("x in ()"))[0].to_s).to eq("x in ()")
      expect(lst.apply(lsp.parse("x in (y)"))[0].to_s).to eq("x in (y)")
      expect(lst.apply(lsp.parse("x in (y, z)"))[0].to_s).to eq("x in (y,z)")
      expect(lst.apply(lsp.parse("x notin ()"))[0].to_s).to eq("x notin ()")
      expect(lst.apply(lsp.parse("x notin (y)"))[0].to_s).to eq("x notin (y)")
      expect(lst.apply(lsp.parse("x notin (y, z)"))[0].to_s).to eq("x notin (y,z)")
      expect(lst.apply(lsp.parse("x notin (y, z)"))[0].to_s).to eq("x notin (y,z)")
      expect(lst.apply(lsp.parse("x notin (y, z)"))[0].to_s).to eq("x notin (y,z)")
    end
  end
end
