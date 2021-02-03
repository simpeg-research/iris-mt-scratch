   function beep_vec(soundfile,hz)
   eval(['load  ' soundfile]);
   beepvec = y;
   if nargin == 2
     sound(y,hz)
   else
     sound(y)
   end
