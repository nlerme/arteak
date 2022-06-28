% Function returning dissimilarity along common borders between adjacent fragments.
% 
% Inputs:
%   * gi1:  image intensities of first fragment (n x 3 matrix of reals [pr_1,pg_2,pb_3;...;pr_n,px_n])
%   * gi2:  image intensities of second fragment (n x 3 matrix of reals [pr_1,pg_2,pb_3;...;pr_n,pg_n,pb_n])
% 
% Outputs:
%   * result:  dissimilarity measure (>=0)
function result = get_dissimilarity( gi1, gi2 )
    mu1      = mean(gi1);
    mu2      = mean(gi2);
    sigma1   = cov(gi1);
    sigma2   = cov(gi2);
    sigma    = (sigma1+sigma2)*0.5;
    delta_mu = (mu1-mu2);
    result   = (1/8)*delta_mu*inv(sigma)*delta_mu' + (1/2)*log(det(sigma)/sqrt(det(sigma1)*det(sigma2)));
end