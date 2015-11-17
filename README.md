diff3
=====
[![Circle CI](https://circleci.com/gh/GoBoundless/dyph3.svg?style=svg)](https://circleci.com/gh/GoBoundless/dyph3)
[![Code Climate](https://codeclimate.com/github/GoBoundless/dyph3/badges/gpa.svg)](https://codeclimate.com/github/GoBoundless/dyph3)
[![Test Coverage](https://codeclimate.com/github/GoBoundless/dyph3/badges/coverage.svg)](https://codeclimate.com/github/GoBoundless/dyph3)

An implementation of the diff3 algorithm in Ruby


### Deploying

We use [GemFury](https://manage.fury.io/dash) to ship private gems like Dyph3. To deploy, follow these steps:

1. Bump the version number in `lib/dyph3/version.rb`
2. Tag it with `git tag v0.0.0` and then `git push origin v0.0.0`
3. Build it with `gem build dyph3.gemspec`
4. Ship it with `fury push dyph3-0.0.0.gem --as=boundless`
