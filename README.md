# SkipSupabase

This package provides Supabase support for Skip app/framework projects.
The Swift side uses the official Supabase iOS SDK directly,
with the various `SkipSupabase*` modules passing the transpiled calls
through to the community Supabase Android SDK.

The current Supabase API coverage is currently very limited.
For an example of using Supabase in a Skip app, see the
[SupaTODO Sample](https://github.com/skiptools/skipapp-supatodo/),
or browse the test cases at
[SkipSupabaseTests.swift](https://github.com/skiptools/skip-supabase/blob/main/Tests/SkipSupabaseTests/SkipSupabaseTests.swift).

## Package

The modules in the SkipSupabase framework project mirror the division of the SwiftPM
modules in the Supabase iOS SDK (at [http://github.com/supabase/supabase-swift](http://github.com/supabase/supabase-swift)),
which is generally mirrored in the division of the Supabase Kotlin Android gradle modules (at [https://github.com/supabase-community/supabase-kt](https://github.com/supabase-community/supabase-kt)).

## Status

This project is in a very early stage, but some amount of Auth and Database API is implemented.
For examples of what is working, see the [SkipSupabaseTests.swift](https://github.com/skiptools/skip-supabase/blob/main/Tests/SkipSupabaseTests/SkipSupabaseTests.swift)
test case, which also shows how setup can be performed.

Please file an [issue](https://github.com/skiptools/skip-supabase/issues)
if there is a particular API that you need for you project, or if something isn't working right.
And please consider contributing to this project by filing
[pull requests](https://github.com/skiptools/skip-supabase/pulls).

### Implementation Details

This package mimics the API shape of the
[supabase-swift](http://github.com/supabase/supabase-swift)
package by adapting it to the
[supabase-kt](https://github.com/supabase-community/supabase-kt)
project. Unlike other Skip API adaptations (like [Skip Firebase](https://github.com/skiptools/skip-firebase)),
this is a challenging task because the Swift and Kotlin interfaces to Supabase
were designed and implemented separately, and so their API shapes differ drastically.

For an example of some of the gymnastics that are required to achieve the goal is a single unified API,
see the implementation of
[SkipSupabase.swift](https://github.com/skiptools/skip-supabase/blob/main/Sources/SkipSupabase/SkipSupabase.swift).


## License

This software is licensed under the
[GNU Lesser General Public License v3.0](https://spdx.org/licenses/LGPL-3.0-only.html),
with the following
[linking exception](https://spdx.org/licenses/LGPL-3.0-linking-exception.html)
to clarify that distribution to restricted envrionments (e.g., app stores)
is permitted:

> This software is licensed under the LGPL3, included below.
> As a special exception to the GNU Lesser General Public License version 3
> ("LGPL3"), the copyright holders of this Library give you permission to
> convey to a third party a Combined Work that links statically or dynamically
> to this Library without providing any Minimal Corresponding Source or
> Minimal Application Code as set out in 4d or providing the installation
> information set out in section 4e, provided that you comply with the other
> provisions of LGPL3 and provided that you meet, for the Application the
> terms and conditions of the license(s) which apply to the Application.
> Except as stated in this special exception, the provisions of LGPL3 will
> continue to comply in full to this Library. If you modify this Library, you
> may apply this exception to your version of this Library, but you are not
> obliged to do so. If you do not wish to do so, delete this exception
> statement from your version. This exception does not (and cannot) modify any
> license terms which apply to the Application, with which you must still
> comply.

