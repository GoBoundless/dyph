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
    result = Dyph3::Differ.text_diff3(base, left, right, markers: {left: "<<<<<<< start", separator: "=======", right: ">>>>>>> changed_b"})
    expect(result).to eq expected_result
  end
end
