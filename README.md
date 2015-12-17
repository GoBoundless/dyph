Dyph3
=====
[![Circle CI](https://img.shields.io/circleci/project/GoBoundless/dyph3/master.svg)](https://circleci.com/gh/GoBoundless/dyph3)
[![Code Climate](https://codeclimate.com/github/GoBoundless/dyph3/badges/gpa.svg)](https://codeclimate.com/github/GoBoundless/dyph3)
[![Test Coverage](https://codeclimate.com/github/GoBoundless/dyph3/badges/coverage.svg)](https://codeclimate.com/github/GoBoundless/dyph3)
[![Documentation](https://img.shields.io/badge/yard-docs-blue.svg)](http://rubydoc.info/github/GoBoundless/dyph3/master)

A library of useful diffing algorithms for Ruby.

## Installation

Add this line to your application's Gemfile:

    gem 'dyph3'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dyph3

# Quick start
## Two way diffing
To diff two arrays:

    left = [:a, :b, :c, :d]
    right = [:b, :c, :d, :e]
    Dyph3::Differ.two_way_diff(left, right)

which will return an array of `Dyph3::Action` with offsets

    [
      <Action::Delete   @new_index=0, @old_index=1, @value=:a>,
      <Action::NoChange @new_index=0, @old_index=1, @value=:b>,
      <Action::NoChange @new_index=1, @old_index=2, @value=:c>,
      <Action::NoChange @new_index=2, @old_index=3, @value=:d>,
      <Action::Add      @new_index=4, @old_index=4, @value=:e>
    ]

## Three way diffing
Three way diffing is able to detect changes between two documents relative to a common base.

### No conflicts
To execute a three way diff and merge:

    left  = [:a, :b, :c, :d]
    base  = [:a, :b, :c]
    right = [:b, :c, :d, :e]
    Dyph3::Differ.merge(left, base, right)

Which returns a `Dyph3::MergeResult` with a list of result outcomes:

    [ <OutCome::Resolved(@result=[:b, :c, :d, :e]> ]

and has `MergeResult#conflict` set to `false`
### Conflicts

Conflicts are when left and right make a change relative to base in the same relative place, so an end user must determine how to merge

For example:

    left  = [:a, :l, :c]
    base  = [:a, :b, :c]
    right = [:a, :r, :c]
    Dyph3::Differ.merge(left, base, right)

returns the following `MergeResult#result`

    [
      <Outcome::Resolved   @result=[:a]>
      <Outcome::Conflicted @base=[:b], @left=[:l], @right=[:r]>,
      <Outcome::Resolved   @result=[:c]>
    ]

and has `MergeResult#conflict` set to `true`

## Split, Join, and Conflict functions
Dyph3 works on arrays of objects that implement equatable and hash (see `Dyph3::Equatable`). For various reasons one might want to delegate the splitting and joining of the input/out to Dyph3. (i.e. so one would not have to `map` over the input and output to do the transformation)

### With merge parameter `lambdas`
One can define `split_funciton`, `join_function`, and `conflict_function` to `Dyph3::Diff.merge` such as splitting on word boundries, (but keeping delimiters):

    split_function =  ->(string) { string.split(/\b/) }

and then a join function to handle the resulting arrays

    join_function =  ->(array) { array.join }

which may be invoked with

    left  = "The quick brown fox left the lazy dog"
    base  = "The quick brown fox jumped over the lazy dog."
    right = "The right brown fox jumped over the lazy dog"
    merge_results = Dyph3::Differ.merge(left, base, right, split_function: split_function, join_function: join_function)
    merge_results.joined_results
will then return

    "The right brown fox left the lazy dog"

### Conflict Handlers
Similarly one can instruct the differ on how to deal with conflicts. The `conflict_function` is passed a list of Outcomes from the diff:

    conflict_funciton = ->(outcome_list) { ... }

which one can then pass to the `Differ#merge` method as

    Dyph3::Differ.merge(left, base, right, conflict_function: conflict_funciton)

### Class Level Processor with Example
In addition to argument level `split`, `join`, `merge` functions, Dyph3 also supports object level processors:

    DIFF_PREPROCESSOR = -> (object) { ... }
    DIFF_POSTPROCESSOR = -> (array) { ... }
    DIFF_CONFLICT_PROCESSOR = ->(outcome_list) { ... }

that will look something like:

    class GreetingCard
      attr_reader :message

      #Dyph3 Processors
      DIFF_PREPROCESSOR  = -> (sentence) { sentence.message.split(/\b/) }
      DIFF_POSTPROCESSOR = -> (array) { array.join }
      DIFF_CONFLICT_PROCESSOR = ->(outcome_list) do
        outcome_list.map do |outcome|
          if outcome.conflicted?
            [
              "<span class='conflict_left'>#{outcome.left.join}</span>",
              "<span class='conflict_base'>#{outcome.base.join}</span>",
              "<span class='conflict_right'>#{outcome.right.join}</span>"
            ].join
          else
            outcome.result.join
          end
        end.join
      end

      def initialize(message)
        @message = message
      end

    end

When there are no conflictes:

    left = GreetingCard.new("Ho! Ho! Ho! Merry Christmas!")
    base = GreetingCard.new("Merry Christmas!")
    right = GreetingCard.new("Merry Christmas! And a Happy New Year")
    Dyph3::Differ.merge(left, base, right).joined_results

    => "Ho! Ho! Ho! Merry Christmas! And a Happy New Year"

and when there are:

    left = GreetingCard.new("Happy Christmas!")
    base = GreetingCard.new("Merry Christmas!")
    right = GreetingCard.new("Just Christmas!")
    Dyph3::Differ.merge(left, base, right).joined_results

    => "<span class='conflict_left'>Happy</span><span class='conflict_base'>Merry</span><span class='conflict_right'>Just</span> Christmas!"


## References:
[Three-way file comparison algorithm (python)](https://www.cbica.upenn.edu/sbia/software/basis/apidoc/v1.2/diff3_8py_source.html)

[Moin Three way differ (python)](http://hg.moinmo.in/moin/2.0/file/4a997d9f5e26/MoinMoin/util/diff3.py)

[Text Diff3 (perl)](http://search.cpan.org/~tociyuki/Text-Diff3-0.10/lib/Text/Diff3.pm)


##The MIT License (MIT)

Copyright © `2016` `Boundless`

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the “Software”), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

