function [ACC_res_mean, NMI_res_mean]=LTS(sourceFeature,targetFeature,targetLabel)
% =====================
% Learning Transferable Subspace for Human Motion Segmentation
% =====================
% Author: Lichen Wang
% Date: Nov. 12, 2018
% E-mail: wanglichenxj@gmail.com

% Input: Source video frame-level feature (d*N_s), each column is a feature
%        Target video frame-level feature (d*N_t), each column is a feature
%        Target video label (1*N_t) for evaluation
% =====================
lambda1 = 0.15;
lam1=2;
mu=0.001;
psize = 80; % Number of dictionary dimension
ksize = 17; % Neighbor number of the generated graph W
maxIter = 20; % Iteration time
alpha = 0.01;
beta = 0.5;
rho = 0.01; % Step size

Xs = normalize(sourceFeature);
Xt = normalize(targetFeature);

X = [Xs Xt]; % Comcatenate source and target feature

[m_xs n_xs]=size(Xs);
[m_xt n_xt]=size(Xt);
[m_x n_x]=size(X);

% ===== Generate W =====
k = ksize;
k2 = (k-1)/2;
W = zeros(n_x, n_x);
for i = 1:n_x
    
    for dis = max(1,i-k2):min(n_x,i+k2)
        W(i,dis)=15*normpdf((dis-i),0,3);
    end
end
for i = 1:n_x
    W(i,i) = 0;
end

% Generate the Lw
DD = diag(sum(W));
Lw = DD - W;

% Calculate Uw and Sw Lw=UwSwUw' (Lw must be symmetric matrix)
[Uw, Sw]=eig(Lw);
Sw_sq=sqrtm(Sw);
Aw=Uw*Sw_sq;
Aw=real(Aw);

P = rand(m_xs, psize); % rendamly generate the diction
Z = rand(n_xs,n_x);
V = zeros(n_xs,n_x);
Y1 = zeros(n_xs,n_x);
Y2 = zeros(n_xs,n_x);
U = zeros(n_xs,n_x);

for loop = 1:maxIter
    
    % Update P
    H = eye(n_x)-1/(n_x)*ones(n_x,n_x);
    tempX=(X-Xs*V);
    [P,~] = eigs(tempX*(tempX')+lambda1*eye(m_xs),tempX*H*(tempX'),psize,'SM');
    
    % Update V    
    leftA=(mu*diag(ones(1,n_xs))+(((P')*Xs)')*((P')*Xs));
    rightB=(mu+lambda1)*Aw*(Aw');
    leftC=-(((P')*Xs)')*(P')*X+Y1-mu*Z-Y2*(Aw')-mu*U*(Aw');
    % solve the equation for V
    V=lyap(leftA,rightB,leftC);
    
    % Update U
    [U1, S1, V1] = svd(V*Aw-Y2/mu, 'econ');
    diagS = diag(S1);
    svp = length(find(diagS > lam1/mu));
    diagS = max(0,diagS - lam1/mu);
    if svp < 0.5
        svp = 1;
    end
    U = U1(:,1:svp)*diag(diagS(1:svp))*V1(:,1:svp)';
    
    % Update Z
    Z = V + Y1 / mu;
    Z(Z<0) = 0;
    
    % Update Y1 Y2
    Y1 = Y1 + mu*(V - Z);
    Y2 = Y2 + mu*(U - V*Aw);   
    
    % ====== Clustering code ======
    nbCluster = length(unique(targetLabel));
    Zt=Z(:,n_xs+1:n_x);
    
    % ====== N-Cut clustering =====
    vecNorm = sum(Zt.^2);
    W2 = (Zt'*Zt) ./ (vecNorm'*vecNorm + 1e-6);
    [oscclusters,~,~] = ncutW(W2,nbCluster);
    clusters = denseSeg(oscclusters, 1);
    clusters = buMissClass(clusters,nbCluster);
    
    accuracy = compacc(clusters, targetLabel); % accuracy result
    res_nmi = nmi(targetLabel, clusters'); % NMI result
    ACC_res(loop) = accuracy;
    NMI_res(loop) = res_nmi;    
    
end
ACC_res_mean = mean(ACC_res(end-1:end));
NMI_res_mean = mean(NMI_res(end-1:end));
end


