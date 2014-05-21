require "dyph3"
require "pry"
require "awesome_print"

describe Dyph3::Differ do
  let(:base) { <<-TEXT
This is the baseline.
The start.
The end.
cats
dogs
pigs
cows
chickens
TEXT
}

  let(:left) { <<-TEXT
This is the baseline.
The start (changed by A).
The end.
cats
dogs
pigs
cows
chickens
TEXT
}

  let(:right) { <<-TEXT
This is the baseline.
The start.
B added this line.
The end.
cats
dogs
pigs
cows
chickens
TEXT
}

  let(:expected_result) {
    r = <<-TEXT
This is the baseline.
<<<<<<<
The start (changed by A).
|||||||
The start.
=======
The start.
B added this line.
>>>>>>>
The end.
cats
dogs
pigs
cows
chickens
TEXT
  r.strip
}

  it "should be tested" do
    result = Dyph3::Differ.merge_text(left, base, right)
    ap result
    
  end

  it "should not explode" do
    result_hash = Dyph3::Differ.text_diff3(left, base, right, markers: {left: "<<<<<<< start", separator: "=======", right: ">>>>>>> changed_b"})
    expect(result_hash[:conflicted]).to be_true
    expect(result_hash[:result]).to eq expected_result
  end

  it "should not be conflicted when not conflicted" do
    result_hash = Dyph3::Differ.text_diff3(left, base, left, markers: {left: "<<<<<<< start", separator: "=======", right: ">>>>>>> changed_b"})
    expect(result_hash[:result]).to eq left.strip #BUGBUG: differ losing a new line?
    expect(result_hash[:conflicted]).to be_false
  end

  it "should not be conflicted when not conflicted" do
    result_hash = Dyph3::Differ.text_diff3(base, base, base, markers: {left: "<<<<<<< start", separator: "=======", right: ">>>>>>> changed_b"})
    expect(result_hash[:result]).to eq base.strip #BUGBUG: differ losing a new line?
    expect(result_hash[:conflicted]).to be_false
  end
end
