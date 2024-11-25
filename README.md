# SkipSupabase

This package provides Supabase support for Skip app/framework projects.
The Swift side uses the official Supabase iOS SDK directly,
with the various `SkipSupabase*` modules passing the transpiled calls
through to the community Supabase Android SDK.

For an example of using Supabase in a Skip app, see the
[SupaTODO Sample](https://github.com/skiptools/skipapp-supatodo/).

## Package

The modules in the SkipSupabase framework project mirror the division of the SwiftPM
modules in the Supabase iOS SDK (at [http://github.com/supabase/supabase-swift](http://github.com/supabase/supabase-swift)),
which is generally mirrored in the division of the Supabase Kotlin Android gradle modules (at [https://github.com/supabase-community/supabase-kt](https://github.com/supabase-community/supabase-kt)).

## Status

This project is in a very early stage, but some amount of Auth and Database API is implemented.
For examples of what is working, see the [SkipSupabaseTests.swift](https://github.com/skiptools/skip-supabase/blob/main/Tests/SkipSupabaseTests/SkipSupabaseTests.swift)
test case, which also shows how setup can be performed.