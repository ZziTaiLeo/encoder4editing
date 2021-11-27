function a = auc(px,py);

[px,si] = sort(px);
py = py(si);

e = [px,py];
a = 0;
de = diff(e);
for i=1:size(e,1)-1
  a = a + de(i,1)*(e(i+1,2) - de(i,2)/2);
end


return
n = length(px);
a = 0;
for i=1:(n-1),
  a = a + (px(i+1)-px(i))*(py(i+1)-py(i))/2;
end
