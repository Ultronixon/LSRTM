classdef oppDFLU < oppSpot
% pSPOT wrapper for DF.m
%
% use:
%   J = oppDFLU(m,Q,LL,UU,Pp,Qp,Rr,dH,model)
%
% see DF.m for further documentation
%
% You may use this code only under the conditions and terms of the
% license contained in the file LICENSE provided with this source
% code. If you do not agree to these terms you may not use this
% software.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Properties
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        mt,Q,LL,UU,Pp,Qp,Rr,dH,model,nfreq,nt;
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods

       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       % Constructor
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       function op = oppDFLU(mt,Q,LL,UU,Pp,Qp,Rr,dH,model)
            nsrc  = size(Q,2);
            nrec  = length(model.xrec)*length(model.zrec);
            nfreq = length(model.freq);
            m = nsrc*nrec*nfreq*model.nsamples;
            n = length(mt)*model.nsamples;
            if nargin < 4
                dogather = 0;
            end

           op = op@oppSpot('oppDFLU', m, n);
           op.cflag     = 1;
           op.linear    = 1;
           op.children  = [];
           op.sweepflag = 0;
           op.mt        = mt;
           op.Q         = Q;
           op.model     = model;
           op.nfreq     = nfreq;
           op.nt        = nsrc*nrec;
           op.LL        = LL;
           op.UU        = UU;
           op.Pp        = Pp;
           op.Qp        = Qp;
           op.dH        = dH;
           op.Rr        = Rr;
       end

    end


    methods ( Access = protected )
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       % Multiply
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       function y = multiply(op,x,mode)
           if mode == 1
                y = DFLU(op.mt,op.Q,x, 1,op.LL,op.UU,op.Pp,op.Qp,op.Rr,op.dH,op.model);
           else %adjoint
                y = DFLU(op.mt,op.Q,x,-1,op.LL,op.UU,op.Pp,op.Qp,op.Rr,op.dH,op.model);
           end
       end %multiply

    end %protected methods

end %classdef
