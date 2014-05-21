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
<<<<<<< start
The start (changed by A).
|||||||
The start.
=======
The start.
B added this line.
>>>>>>> changed_b
The end.
cats
dogs
pigs
cows
chickens
TEXT
  r.strip
}

  it "should not explode" do
    result = Dyph3::Differ.merge_text(left, base, right, markers: {left: "<<<<<<< start", base: "|||||||", right: "=======", close: ">>>>>>> changed_b"})
    expect(result[:conflict]).to eq(1)
    expect(result[:body]).to eq expected_result
  end

  it "should not be conflicted when not conflicted" do
    result = Dyph3::Differ.merge_text(left, base, left, markers: {left: "<<<<<<< start", base: "|||||||", right: "=======", close: ">>>>>>> changed_b"})
    expect(result[:body]).to eq left.strip #BUGBUG: differ losing a new line?
    expect(result[:conflict]).to eq(0)
  end

  it "should not be conflicted when not conflicted" do
    result = Dyph3::Differ.merge_text(base, base, base, markers: {left: "<<<<<<< start", base: "|||||||", right: "=======", close: ">>>>>>> changed_b"})
    expect(result[:body]).to eq base.strip #BUGBUG: differ losing a new line?
    expect(result[:conflict]).to eq(0)
  end
  
  it "should allow you to not include the base in the result" do
    expected_result = <<-TEXT.strip
This is the baseline.
<<<<<<< start
The start (changed by A).
=======
The start.
B added this line.
>>>>>>> changed_b
The end.
cats
dogs
pigs
cows
chickens
TEXT
    
    result = Dyph3::Differ.merge_text(left, base, right, include_base: false, markers: {left: "<<<<<<< start", base: "|||||||", right: "=======", close: ">>>>>>> changed_b"})
    expect(result[:conflict]).to eq(1)
    expect(result[:body]).to eq expected_result
  end
end
