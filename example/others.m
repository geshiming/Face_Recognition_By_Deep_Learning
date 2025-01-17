% others 
% Copyright (C) 2013 Michael Shing 
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.


warning off;
addpath('../');
addpath('../minFunc/');

load('saves/S.mat');

dir = 'D:/LBP/pie/complex';
mat = 'saves/complex.mat';
labelmat = 'saves/complex_label.mat';
imgType = '*.jpg';

if ~exist(mat)
    All = loadImages(dir,imgType);
    All = All/255;
    save(mat,'All');
else
    load(mat); 
end

if ~exist(labelmat);
    All_label = loadLabels(dir,imgType);
    save(labelmat,'All_label');
else
    load(labelmat); 
end

numdata = size(All,2);
datadim = size(All,1);

randIndex = randperm(numdata);

numtrain = ceil(0.75*numdata);

N = All(:,randIndex(1:numtrain));
N_label = All_label(randIndex(1:numtrain));

numtest = numdata-numtrain;

N_test = All(:,randIndex(numtrain+1:end));
N_test_label =  All_label(randIndex(numtrain+1:end));

clear All All_label;
%--------------------------------------------------------------------------
%                                options
%--------------------------------------------------------------------------

fprintf('set options...\n\n');
xxx=zeros(77,1);
yyy=zeros(77,1);
zzz=zeros(77,1);
for kkk=1:77
SKIP_NCA = 0;
searchRadius = 10*kkk;
selftest = 1;
test = 1; % should be 1 only by selftest is open ,I do it for memory reducing 
alltest=1;
S.learning.weight_decay = 3e-3;
S.ncaOBJ = -1;
S.early_stop = 0;
S.batchloop_times = 2;
S.optimize.maxIter = 50;
S.learning.minibatch_sz = 600;
S.optimize.corr = 15;
%--------------------------------------------------------------------------
%                              resconstruction
%--------------------------------------------------------------------------
fprintf('resconstruction...\n\n');

NH = sdae_get_hidden (N, S);
%save 'sdae_mnist_vis.mat' H X_labels;
NV = sdae_get_visible (NH, S);


real = N(:,(1:10));
data = NV(:,(1:10));
label = N_label(1:10);
for i=1:10
    I = data(:,i)*255;
    if I>255
        I=255;
    end
    if I<0
        I=0;
    end
    I = reshape(I,sqrt(datadim),sqrt(datadim));
    namestr = fullfile('saves/',['recIMG_', num2str(i), '.jpg']);
    I = uint8(I);
    imwrite(I,namestr);
end 

for i=1:10
    I = real(:,i)*255;
    if I>255
        I=255;
    end
    if I<0
        I=0;
    end
    I = reshape(I,sqrt(datadim),sqrt(datadim));
    recnamestr = fullfile('saves/',['IMG_', num2str(i), '.jpg']);
    I = uint8(I);
    imwrite(I,recnamestr);
end

clear NH NV;
%--------------------------------------------------------------------------
%                               NCA
%--------------------------------------------------------------------------
fprintf('NCA...\n\n');

if ~SKIP_NCA
    if ~exist('saves/S_nca.mat','file');

        S = nca(N, N_label, S);
        save('saves/S_nca.mat','S');
    else
        load('saves/S_nca.mat');
    end
end

%--------------------------------------------------------------------------
%                          making threhold
%--------------------------------------------------------------------------

fprintf('making threhold...\n\n');

if ~exist('saves/threhold.mat','file');

        load('saves/X_LFW.mat');
        XH = sdae_get_hidden (X, S);
        threhold = median(XH,2);
        save('saves/threhold.mat','threhold');
        clear X XH;
else
        load('saves/threhold.mat');
end
     
%--------------------------------------------------------------------------
%                   selftest: means test the train sets
%-------------------------------------------------------------------------- 
fprintf('selftest...\n');

if (selftest)
    hammingAcc = 0;
    euclidAcc = 0;
    NH = sdae_get_hidden (N, S);
    
    bin = code2bin(NH,threhold);
    
    bytes = bin2bytes(uint8(bin),ones(size(bin,1),1),8);
    
    for p = 1:numtrain
        onebyte = bytes(:,p);
        [hammingDistance,hsortIndex] = HammingDist(onebyte,bytes,searchRadius);
        if(N_label(p)==N_label(hsortIndex(2)))
            hammingAcc = hammingAcc+1;
        end
        [EuclideanDistance ,esortIndex]= EuclidDist(NH(:,p),NH,hsortIndex);
        if(N_label(p)==N_label(esortIndex(2)))
            euclidAcc = euclidAcc+1;
        end
    end
    
    fprintf('Hamming distance Accuracy: %0.3f%%\n', (hammingAcc/numtrain)*100);
    fprintf('Euclidean distance Accuracy: %0.3f%%\n\n', (euclidAcc/numtrain)*100);
    
end


%--------------------------------------------------------------------------
%                                test
%-------------------------------------------------------------------------- 
fprintf('test...\n');
tic;
if(test)
    hammingAcc = 0;
    euclidAcc = 0;
    NH_test = sdae_get_hidden (N_test, S);
    NH = [NH,NH_test];
    bin_test = code2bin(NH_test,threhold);
    
    bytes_test = bin2bytes(uint8(bin_test),ones(size(bin_test,1),1),8);
    bytes = [bytes , bytes_test];
    N_label=[N_label;N_test_label];
     for p = 1:numtest
          onebyte_test = bytes_test(:,p);
          [hammingDistance_test,hsortIndex_test] = HammingDist(onebyte_test,bytes,searchRadius);
          if(N_test_label(p)==N_label(hsortIndex_test(2)))
             hammingAcc = hammingAcc+1;
          end

          [EuclideanDistance_test,esortIndex_test]= EuclidDist(NH_test(:,p),NH,hsortIndex_test);
          if(N_test_label(p)==N_label(esortIndex_test(2)))
                euclidAcc = euclidAcc+1;
          end

     end
     
     fprintf('Hamming distance Accuracy: %0.3f%%\n', (hammingAcc/numtest)*100);
     fprintf('Euclidean distance Accuracy: %0.3f%%\n\n', (euclidAcc/numtest)*100);

end

zzz(kkk,1)=toc;
xxx(kkk,1) = searchRadius;
yyy(kkk,1)=(euclidAcc/numtest)*100;

%--------------------------------------------------------------------------
%                             alltest
%-------------------------------------------------------------------------- 
% fprintf('alltest...\n');
% 
% if(alltest)
%     hammingAcc = 0;
%     euclidAcc = 0;
%     for p = 1:numdata
%           onebyte = bytes(:,p);
%           [hammingDistance,hsortIndex] = HammingDist(onebyte,bytes,searchRadius);
%           if(N_label(p)==N_label(hsortIndex(2)))
%              hammingAcc = hammingAcc+1;
%           end
% 
%           [EuclideanDistance,esortIndex]= EuclidDist(NH(:,p),NH,hsortIndex);
%           if(N_label(p)==N_label(esortIndex(2)))
%                 euclidAcc = euclidAcc+1;
%           end
% 
%      end
%      
%      fprintf('Hamming distance Accuracy: %0.3f%%\n', (hammingAcc/numdata)*100);
%      fprintf('Euclidean distance Accuracy: %0.3f%%\n\n', (euclidAcc/numdata)*100);
% end



%--------------------------------------------------------------------------
%                         draw minimal ditance
%-------------------------------------------------------------------------- 
% 
% fprintf('draw minimal ditance between and winthin classes...\n');
% 
% drawMinDist;
end

plot(xxx,yyy,'k-','linewidth',2);

