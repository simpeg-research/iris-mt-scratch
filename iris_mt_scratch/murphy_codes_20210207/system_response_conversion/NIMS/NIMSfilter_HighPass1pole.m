% #######################################################################
% # Analogue single-pole Butterworth high-pass filter on electric channels
function PZ = NIMSfilter_HighPass1pole(T0,fn)
    % output format: # of zeros, # of poles, A0, zeros, poles
    
    pole_Re = -2.*pi/T0;
    pole_Im = 0;
    zero_Re = 0;
    zero_Im = 0;
    
    % calculate normalization factor at fn
    a = pole_Re/(2.*pi*fn);
    A0 = sqrt(1. + a^2);
    PZ = [1,1,A0,zero_Re,zero_Im,pole_Re,pole_Im];

end

% sub HighPass1pole {
%  my ($T0,$fn)=@_;
%  print "High pass T0 (sec), fn: $T0, $fn\n";
%  my $pi=3.14159265358979;
%  my $pole_Re=-2.*$pi/$T0;
%  my $pole_Im=0;
%  my $zero_Re=0;my $zero_Im=0;
% # calculate normalization factor at $fn
%  my $a=$pole_Re/(2*$pi*$fn);
%  my $A0=sqrt(1.+$a*$a);
%  my @PZ=($pole_Re,$pole_Im,$zero_Re,$zero_Im,$A0);
%  #print "High Pass Pole:\n";
%  #print "($pole_Re,$pole_Im)\n";
%  #print "High Pass Zero:\n";
%  #print "($zero_Re,$zero_Im)\n";
%  return @PZ;
% };
% ########################################################################
% # 3 poles, no zeros
% sub LowPassButter3pole {
%  my ($T0,$fn)=@_;
%  print "Low pass 3 pole T0 (sec), fn: $T0,$fn\n";
%  my $pi=3.14159265358979;
%  my $omega=2.*$pi/$T0;
% # coefficients obtained with matlab functions [z,p,k]=buttap(3);
% # giving pole values on unit circle
%  $p1_Re=-0.5*$omega;$p1_Im=0.866*$omega;
%  $p2_Re=-0.5*$omega;$p2_Im=-0.866*$omega;
%  $p3_Re=-1.*$omega;$p3_Im=0;
% # Normalization factor (product of poles), but correction for normalization
% # frequency fn must be considered, ie. Ao is product of (2*pi*fn-Pj), where Pj is pole
% # All the fuss above, since no complex operations are supported in Perl
%  #my $A0=abs(($p1_Re**2+$p1_Im**2)*$p3_Re); # i.e (a+bi)*(a-bi)*c=(a*a+b*b)*c;
%  my $a=$p1_Re;my $b=$p1_Im;my $c=2*$pi*$fn;
%  my $A=2*$a*($a*$a+$b*$b-$c*$c); # real part of product of "corrected" with -2*pi*fn poles
%  my $B=$c*(5*$a*$a+b*$b-$c*$c);  # imag part of product of "corrected" with -2*pi*fn poles
%  my $A0=sqrt($A*$A+$B*$B);
%  print "Normalization factor (3poles): $A0\n";
%  my @P=($p1_Re,$p1_Im,$p2_Re,$p2_Im,$p3_Re,$p3_Im,$A0);
%  return @P;
% };
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
% ########################################################################
% sub ComplexProd {
%  my ($a1,$b1,$a2,$b2)=@_;
%  my $a=$a1*$a2-$b1*$b2;
%  my $b=$a1*$b2+$a2*$b1;
%  my @P=($a,$b);
%  return @P;
% }
