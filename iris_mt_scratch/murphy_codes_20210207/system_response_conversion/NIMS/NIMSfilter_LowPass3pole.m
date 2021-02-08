% ########################################################################
% # 3 poles, no zeros Butterworth filter for NIMS magnetic fields
function P = NIMSfilter_LowPass3pole(T0,fn)
    % output format: # of zeros, # of poles, A0, zeros, poles

    omega=2.*pi/T0;
    
    % coefficients obtained with matlab functions [z,p,k]=buttap(3);
    % giving pole values on LEFT (real) side of unit circle
    p1_Re=-0.5*omega;   p1_Im= 0.866*omega; p1 = p1_Re + 1i*p1_Im;
    p2_Re=-0.5*omega;   p2_Im=-0.866*omega; p2 = p2_Re + 1i*p2_Im;
    p3_Re=-1.*omega;    p3_Im= 0;           p3 = p3_Re + 1i*p3_Im;

    % Normalization factor (product of poles), but correction for normalization
    % frequency fn must be considered, ie. A0 is product of (2*pi*fn-Pj), where Pj is pole
    % All the fuss above, since no complex operations are supported in Perl
    
    % Normalization factor
    % A0=abs((p1_Re^2+p1_Im^2)*(p3_Re^2+p3_Im^2)*p5_Re);
	c=2*pi*fn;
    a=p1_Re;
    b=p1_Im;
    A = 2*a*(a*a+b*b-c*c);
    B = c*(5*a*a+b*b-c*c);
    A0 = sqrt(A^2+B^2);
    P = [0,3,A0,p1_Re,p1_Im,p2_Re,p2_Im,p3_Re,p3_Im];

end

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
