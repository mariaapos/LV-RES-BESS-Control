function [Q] = QV(Pg,Pn,Vmin,Vmax,V,Qold,dV)
    
    Qmax=sqrt(abs((1.1*Pn^2)-Pg^2));
    
    if V<Vmin 
        q=1;

    elseif V>=Vmax
        q=-1;
        
    elseif  V<(1+(dV/2)) && V>=(1-(dV/2)) 
        q=0;
    elseif V<Vmax && V>=(1+(dV/2)) 
        a=-(1/(Vmax-(dV/2)-1));
        b=((dV/2)+1)/(Vmax-(dV/2)-1);
        q=a*V+b;
    
    else 
        a=1/(Vmin+(dV/2)-1);
        b=((dV/2)-1)/(Vmin+(dV/2)-1);
        q=a*V+b;
    end 

    Qnew=q*Qmax;
    Q=Qold+(Qnew-Qold)/10;
  
end 