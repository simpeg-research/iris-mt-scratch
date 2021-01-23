idec = 1;
X = FCAobj.Array{1}.FC(idec).FC;
bsFile = '../CFG/bs_test.cfg';
bandLims = ReadBScfg(bsFile);

for k = 1:8
    i1 = bandLims(k,2);
    i2 = bandLims(k,3);
    H = X(1:2,i1:i2,:);
    E = X(4:5,i1:i2,:);
    [nch,nfc,nseg] = size(H);
    H = reshape(H,nch,nfc*nseg);
    E = reshape(E,nch,nfc*nseg);
    H = H.';
    E = E.';
    Z = inv(H'*H)*H'*E
end