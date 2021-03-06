require 'spec_helper'

module ROF
  describe "translate CSV" do
    it "requires the columns type and owner" do
      s = "dc:title,access,owner"
      expect{TranslateCSV.run(s)}.to raise_error

      s = "dc:title,access,type"
      expect{TranslateCSV.run(s)}.to raise_error

      s = "dc:title,type,owner,access"
      expect(TranslateCSV.run(s)).to eq([])
    end

    it "requires rows to have an owner and type" do
      s = %q{type,owner
      Work,
      }
      expect{TranslateCSV.run(s)}.to raise_error
    end

    it "deocdes the access field into rights" do
      s = %q{type,owner,access
      Work,user1,"private;edit=user2,user3"
      }
      rof = TranslateCSV.run(s)
      expect(rof).to eq([{"type" => "Work", "owner" => "user1", "rights" => {"edit" => ["user1", "user2", "user3"]}}])
    end

    it "puts metadata into substructure" do
      s = %q{type,owner,dc:title,foaf:name
      Work,user1,"Q, A Letter",Jane Smith|Zander
      }
      rof = TranslateCSV.run(s)
      expect(rof).to eq([{
        "type" => "Work",
        "owner" => "user1",
        "rights" => {"edit" => ["user1"]},
        "metadata" => {
          "@context" => RdfContext,
          "dc:title" => "Q, A Letter",
          "foaf:name" => ["Jane Smith", "Zander"]}
      }])
    end

    it "renames curate_id to pid" do
      s = %q{type,owner,curate_id
      Work,user1,abcdefg
      }
      rof = TranslateCSV.run(s)
      expect(rof).to eq([{
        "type" => "Work",
        "owner" => "user1",
        "pid" => "abcdefg",
        "rights" => {"edit" => ["user1"]}
      }])
    end

    it "strips space around pipes" do
      s = %q{type,owner,dc:title,foaf:name
      Work,user1,"Q, A Letter",Jane Smith | Zander
      }
      rof = TranslateCSV.run(s)
      expect(rof).to eq([{
        "type" => "Work",
        "owner" => "user1",
        "rights" => {"edit" => ["user1"]},
        "metadata" => {
          "@context" => RdfContext,
          "dc:title" => "Q, A Letter",
          "foaf:name" => ["Jane Smith", "Zander"]}
      }])
    end

    it "handles follow-on generic files" do
      s = %q{type,owner,dc:title,files
      Work,user1,"Q, A Letter",thumb
      +,user1,,extra file.txt
      }
      rof = TranslateCSV.run(s)
      expect(rof).to eq([{
        "type" => "Work",
        "owner" => "user1",
        "rights" => {"edit" => ["user1"]},
        "metadata" => {
          "@context" => RdfContext,
          "dc:title" => "Q, A Letter"},
        "files" => [
          "thumb",
          {
            "type"  => "+",
            "owner" => "user1",
            "files" => ["extra file.txt"],
            "rights" => {"edit" => ["user1"]}
          }]
      }])
    end

    it "raises an error if a follow-on file has no preceeding work" do
      s = %q{type,owner,dc:title,files
      +,user1,,extra file.txt
      }
      expect {TranslateCSV.run(s)}.to raise_error
    end


  end
end
