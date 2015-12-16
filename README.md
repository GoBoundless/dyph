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
      Action::Delete.new(new_index: 0, old_index: 1, value: :a),
      Action::NoChange.new(new_index: 0, old_index: 1, value: :b),
      Action::NoChange.new(new_index: 1, old_index: 2, value: :c),
      Action::NoChange.new(new_index: 2, old_index: 3, value: :d),
      Action::Add.new(new_index: 4, old_index: 4, value: :e)
    ]

## Three way diffing
Three way diffing is able to detect changes between two documents relative to a common base.

### No conflicts
To execute a three way diff and merge:

    left  = [:a, :b, :c, :d]
    base  = [:a, :b, :c]
    right = [:b, :c, :d, :e]
    Dyph3::Differ.merge(left, base, right)

Which returns a Dyph3::MergeResult with a list of result outcomes:

    [ OutCome::Resolved.new(result: [:b, :c, :d, :e] ]

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
      Outcome::Resolved.new(result: [:a]),
      Outcome::Conflicted.new(base: [:b], left: [:l], right: [:r]),
      Outcome::Resolved.new(result: [:c])
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
### By class level preprocessors
### Custom Conflict handlers

