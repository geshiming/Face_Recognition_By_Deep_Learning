% sdae_get_visible
% Copyright (C) 2011 KyungHyun Cho, Tapani Raiko, Alexander Ilin
%
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or (at your option) any later version.
%
%This program is distributed in the hope that it will be useful,
%but WITHOUT ANY WARRANTY; without even the implied warranty of
%MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%GNU General Public License for more details.
%
%You should have received a copy of the GNU General Public License
%along with this program; if not, write to the Free Software
%Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
%
function [x_mf] = sdae_get_visible(h0, S)

layers = S.structure.layers;
n_layers = length(layers);
layerstype= S.layerstype(n_layers:2*n_layers-1);
x_mf = h0;

for l = 1:n_layers-1
    
    x_mf = bsxfun(@plus, S.W2{l}*x_mf, S.vbiases{l});

    if layerstype(l+1)
        x_mf = sigmoid(x_mf);
    end
end


