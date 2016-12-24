clear classes

addpath('../lib');

if exist('datetime') ~= 2 || exist('containers.Map') ~= 8
    addpath('../lib/polyfill', '-end');
end

if exist('debug_on_error')
    debug_on_error(true);
end