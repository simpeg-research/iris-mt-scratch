% ########################################################################
% # 5 poles, no zeros Butterworth filter for NIMS magnetic fields
function P = NIMSfilter_LowPass5pole(T0,fn)
    % output format: # of zeros, # of poles, A0, zeros, poles

    omega=2.*pi/T0;
    
    % coefficients obtained with matlab functions [z,p,k]=buttap(5);
    % giving pole values on LEFT (real) side of unit circle
    p1_Re=-0.309*omega; p1_Im= 0.9511*omega; p1 = p1_Re + 1i*p1_Im;
    p2_Re=-0.309*omega; p2_Im=-0.9511*omega; p2 = p2_Re + 1i*p2_Im;
    p3_Re=-0.809*omega; p3_Im= 0.5878*omega; p3 = p3_Re + 1i*p3_Im;
    p4_Re=-0.809*omega; p4_Im=-0.5878*omega; p4 = p4_Re + 1i*p4_Im;
    p5_Re=-1.*omega;    p5_Im= 0;            p5 = p5_Re + 1i*p5_Im;
    
    % Normalization factor
    % A0=abs((p1_Re^2+p1_Im^2)*(p3_Re^2+p3_Im^2)*p5_Re);
	c=1i*2*pi*fn;
    p1=(p1-c)*(p2-c);
    p2=(p3-c)*(p4-c);
    p1=p1*p2;
    p0=p1*(p5-c);
    A0=abs(p0);
    P = [0,5,A0,p1_Re,p1_Im,p2_Re,p2_Im,p3_Re,p3_Im,p4_Re,p4_Im,p5_Re,p5_Im];

end

% ########################################################################
% # 5poles, no zeros
% sub LowPassButter5pole {
%  my ($T0,$fn)=@_;
%  print "Low pass 5 pole T0 (sec), fn: $T0,$fn\n";
%  my $pi=3.14159265358979;
%  my $omega=2.*$pi/$T0;
% # coefficients obtained with matlab functions [z,p,k]=buttap(5);
% # giving pole values on LEFT (real) side of unit circle
%  my $p1_Re=-0.309*$omega;$p1_Im=0.9511*$omega;
%  my $p2_Re=-0.309*$omega;$p2_Im=-0.9511*$omega;
%  my $p3_Re=-0.809*$omega;$p3_Im=0.5878*$omega;
%  my $p4_Re=-0.809*$omega;$p4_Im=-0.5878*$omega;
%  my $p5_Re=-1.*$omega;$p5_Im=0;
% # Normalization factor
%  ###  my $A0=abs(($p1_Re**2+$p1_Im**2)*($p3_Re**2+$p3_Im**2)*$p5_Re);
%  my $c=2*$pi*$fn;
%  @p=ComplexProd($p1_Re,$p1_Im-$c,$p2_Re,$p2_Im-$c);$P1_Re=@p[0];$P1_Im=@p[1];
%  @p=ComplexProd($p3_Re,$p3_Im-$c,$p4_Re,$p4_Im-$c);$P2_Re=@p[0];$P2_Im=@p[1];
%  @p=ComplexProd($P1_Re,$P1_Im,$P2_Re,$P2_Im);$P1_Re=@p[0];$P1_Im=@p[1];
%  @p=ComplexProd($P1_Re,$P1_Im,$p5_Re,$p5_Im-$c);
%  $A0=sqrt(@p[0]*@p[0]+@p[1]*@p[1]);
%  print "Normalization factor (5poles): $A0\n";
%  my @P=($p1_Re,$p1_Im,$p2_Re,$p2_Im,$p3_Re,$p3_Im,$p4_Re,$p4_Im,$p5_Re,$p5_Im,$A0);
%  return @P;
% };