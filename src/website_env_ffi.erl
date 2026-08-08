-module(website_env_ffi).
-export([base_path/0]).

%% Reads GLEMY_WEBSITE_BASE_PATH at build time. Unset -> "" (correct for
%% local dev, serving `dist` at the domain root, and any future custom
%% domain). Set by .github/workflows/deploy.yml to "/glemy-website" when
%% deploying to GitHub Pages' project-site URL, which serves the site
%% under that subpath rather than the domain root.
base_path() ->
    case os:getenv("GLEMY_WEBSITE_BASE_PATH") of
        false -> <<"">>;
        Value -> list_to_binary(Value)
    end.
