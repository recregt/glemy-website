-module(website_env_ffi).
-export([base_url/0]).

%% Reads GLEMY_WEBSITE_BASE_URL at build time. Unset -> "" (correct for
%% local dev, serving `dist` at the domain root). Set by
%% .github/workflows/deploy.yml to actions/configure-pages' own base_url
%% output (e.g. "https://recregt.github.io/glemy-website") -- used as the
%% prefix for every internal link/asset (GitHub Pages serves a project
%% site under a /<repo-name> subpath, not the domain root, so a
%% root-relative href 404s) and, absolute, for canonical/OpenGraph URLs
%% and the sitemap/Atom feed, which both require fully-qualified URLs.
base_url() ->
    case os:getenv("GLEMY_WEBSITE_BASE_URL") of
        false -> <<"">>;
        Value -> list_to_binary(Value)
    end.
