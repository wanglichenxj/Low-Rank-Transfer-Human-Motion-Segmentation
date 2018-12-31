% =====================
% Low-Rank Transfer Human Motion Segmentation
% =====================
% Author: Lichen Wang
% Date: Dec. 21, 2018
% E-mail: wanglichenxj@gmail.com

% Cite:
% @ARTICLE{LTS_Lichen_TIP18, 
% 	author={Lichen Wang and Zhengming Ding and Yun Fu}, 
% 	journal={IEEE Transactions on Image Processing}, 
% 	title={Low-Rank Transfer Human Motion Segmentation}, 
% 	year={2019}, 
% 	volume={28}, 
% 	number={2}, 
% 	pages={1023-1034},
% 	doi={10.1109/TIP.2018.2870945},
% }
% =====================
% clc;
clear all;
close all;
rand('state',123);

% Evaluation and clustering code
addpath('Evaluation');
addpath('Evaluation/ncut');
% Features of Keck and Weizmann datasets
addpath('Datasets');

% ==============
% Set Weizmann as source and Keck as target video
disp('==== Weizmann-Source Keck-Target ====');
ACC_res=[];
NMI_res=[];

for i=1:4
    
    % Load source video
    [sourceFeature, ~]=load_Weiz(4);
    % Load i-th target video
    [targetFeature, targetLabel]=load_Keck(i);
    % Video segmentation and output performance evaluation
    [acc, nmi]=LTS(sourceFeature,targetFeature,targetLabel);
    disp(['Person = ',num2str(i),'  ACC = ',num2str(acc),'  NMI = ',num2str(nmi)]);
    ACC_res=[ACC_res acc];
    NMI_res=[NMI_res nmi];
    
end
% Get average performance
mean_acc=mean(ACC_res);
mean_nmi=mean(NMI_res);
disp(['Mean  ACC = ',num2str(mean_acc),'  NMI = ',num2str(mean_nmi)]); % show result



