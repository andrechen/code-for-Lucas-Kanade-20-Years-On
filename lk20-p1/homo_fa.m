function fit = homo_fa(img, tmplt, p_init, n_iters, verbose)
% HOMO_FA - Homography image alignment using forwards-additive algorithm
%   FIT = HOMO_FA(IMG, TMPLT, P_INIT, N_ITERS, VERBOSE)
%   Align the template image TMPLT to an example image IMG using a
%   projective warp initialised using P_INIT. Iterate for N_ITERS iterations.
%   To display the fit graphically set VERBOSE non-zero.
%
%   p_init = [p1, p4, p7     paper_equivalent = [p1, p3, p5
%             p2, p5, p8                         p2, p4, p6
%             p3, p6, 1];                        p7, p8, 1];
%
%   This assumes greyscale images and rectangular templates.
%
%   c.f. Lucas-Kanade 

% Iain Matthews, Simon Baker, Carnegie Mellon University, Pittsburgh
% $Id: homo_fa.m,v 1.1.1.1 2003/08/20 03:07:35 iainm Exp $

if nargin<5 verbose = 0; end
if nargin<4 error('Not enough input arguments'); end

% Common initialisation
init_h;

% Pre-computable things ---------------------------------------------------

% 3a) Compute image gradients - will warp these images in step 3b)
[img_dx img_dy] = gradient(img);


% Lucas-Kanade, Forwards Additive Algorithm -------------------------------

for f=1:n_iters
	% 1) Compute warped image with current parameters
	IWxp = warp_h(img, warp_p, tmplt_pts);

	% 2) Compute error image
	error_img = tmplt - IWxp;
		
	% -- Save current fit parameters --
	fit(f).warp_p = warp_p;
	fit(f).rms_error = sqrt(mean(error_img(:) .^2));
	
	% -- Show fitting? --
	if verbose
		disp(['Forwards-Additive [',num2str(f-1),']: RMS = ',num2str(fit(f).rms_error)]);
		verb_plot_h(verb_info, warp_p, tmplt_pts, error_img);
	end
	
	% -- Really iteration 1 is the zeroth, ignore final computation --
	if (f == n_iters) break; end

	% 3b) Evaluate gradient
	nabla_Ix = warp_h(img_dx, warp_p, tmplt_pts);
	nabla_Iy = warp_h(img_dy, warp_p, tmplt_pts);

	% 4) Evaluate Jacobian
	dW_dp = jacobian_h(w, h, warp_p);
	
	% 5) Compute steepest descent images, VI_dW_dp
	VI_dW_dp = sd_images(dW_dp, nabla_Ix, nabla_Iy, N_p, h, w);
	
	% 6) Compute Hessian and inverse
	H = hessian(VI_dW_dp, N_p, w);
	H_inv = inv(H);

	% 7) Compute steepest descent parameter updates
	sd_delta_p = sd_update(VI_dW_dp, error_img, N_p, w);

	% 8) Compute gradient descent parameter updates
	delta_p = H_inv * sd_delta_p;

	% 9) Update warp parmaters
	warp_p = update_step(warp_p, delta_p);	
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function warp_p = update_step(warp_p, delta_p)
% Compute and apply the update

delta_p = [delta_p; 1];
delta_p = reshape(delta_p, 3, 3);
warp_p = warp_p + delta_p;
warp_p(3,3) = 1;
