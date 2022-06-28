% Function printing a message if and only if verbose mode is enabled
% 
% Inputs:
%   * s:        string to print
%   * verbose:  enables/disables printing of messages
% 
% Outputs:
%   None
function msg( s, verbose )
    if verbose
        disp(s);
    end
end