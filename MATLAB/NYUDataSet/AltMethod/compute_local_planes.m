% This file is adapted from NYU Depth V2 Toolbox
% URL: http://cs.nyu.edu/~silberman/datasets/nyu_depth_v2.html
% Computes local surface normal information. Note that in this file, the Y
% coordinate points up, consistent with the image coordinate frame.
%
% Args:
%   X - Nx1 column vector of 3D point cloud X-coordinates
%   Y - Nx1 column vector of 3D point cloud Y-coordinates
%   Z - Nx1 column vector of 3D point cloud Z-coordinates.
%   sz - [HxW] image size
%   params
%
% Returns: 
%   normMap - HxWx3 matrix of surface normals at each pixel.
%   normConfs - HxW image of confidences.
function normMap = compute_local_planes(X, Y, Z, sz)

  H = sz(1);
  W = sz(2);
  
  % Plane Fitting Parameters %
  blockWidths = [1 3 6 9];
  relDepthThresh = 0.05;
  
  
  N = H * W;

  pts = [X(:) Y(:) Z(:) ones(N, 1)];

  [u, v] = meshgrid(1:W, 1:H);

  blockWidths = [-blockWidths 0 blockWidths];
  [nu, nv] = meshgrid(blockWidths, blockWidths);

  nx = zeros(H, W);
  ny = zeros(H, W);
  nz = zeros(H, W);
  nd = zeros(H, W);
  normConfs = zeros(H, W);

  ind_all = find(Z);
  for k = ind_all(:)'        

    u2 = u(k)+nu;
    v2 = v(k)+nv;

    % Check that u2 and v2 are in image.
    valid = (u2 > 0) & (v2 > 0) & (u2 <= W) & (v2 <= H);
    u2 = u2(valid);
    v2 = v2(valid);
    ind2 = v2 + (u2-1)*H;

    % Check that depth difference is not too large.
    valid = abs(Z(ind2) - Z(k)) < Z(k) * relDepthThresh;
    u2 = u2(valid);
    v2 = v2(valid);
    ind2 = v2 + (u2-1)*H;

    if numel(u2) < 3
      continue;
    end

    A = pts(ind2, :);        
    [eigv, l] = eig(A'*A);
    nx(k) = eigv(1,1);
    ny(k) = eigv(2,1);
    nz(k) = eigv(3,1);
    nd(k) = eigv(4,1);
    normConfs(k) = 1 - sqrt(l(1) / l(2,2)); 
  end
  
  % Make all the vectors point at the camera
  flip = reshape(sign(X(:).*nx(:)+Y(:).*ny(:)+Z(:).*nz(:)+eps),size(nx));
  normMap = bsxfun(@times,flip,cat(3,nx,ny,nz));
  % Normalisation
  normMap = bsxfun(@rdivide,normMap,sum(normMap.^2,3).^0.5+eps);

end
