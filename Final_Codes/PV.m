function [P] = PV(Pn,V1,V2,V,Pold)
    
    clear Qnew
    
    
    if V<V1 
        p=1;
        
    elseif V>V2 
        p=0;
        
    else 
        a=1/(V1-V2);
        b=-V2/(V1-V2);
        p=a*V+b;
    end 

    Pnew=p*Pn; 
    P=Pold+(Pnew-Pold)/50;

end 