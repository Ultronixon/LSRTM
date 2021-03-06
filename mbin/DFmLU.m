function output = DFmLU(m,Q,input,flag,LL,UU,Pp,Qp,Rr,dH,model)
% Frequency domain modeling in the Born approximation. This is the
% Jacobian of F(m,Q,model).
%
% use:
%   output = DF(m,Q,input,flag,model,{gather})
% input:
%   m                 - vector with gridded squared slowness in [km^2/s^2]
%   Q                 - source matrix. size(Q,1) must match source grid
%                       definition, size(Q,2) determines the number of
%                       sources, if size(Q,3)>1, it represents a
%                       frequency-dependent source and has to be
%                       distributed over the last dimension.
%   input             - flag= 1: vector with gridded slowness perturbation
%                       flag=-1: vectorized data cube of size nrec xnrec x nfreq
%   flag              -  1: forward mode
%                       -1: adjoint mode
%   model.{o,d,n}     - regular grid: z = ox(1) + [0:nx(1)-1]*dx(1), etc
%   model.nb          - number of extra points for absorbing boundary on each side
%   model.freq        - frequencies
%   model.f0          - peak frequency of Ricker wavelet, 0 for no wavelet.
%   model.t0          - phase shift [s] of wavelet.
%   model.{zsrc,xsrc} - vectors describing source array
%   model.{zrec,xrec} - vectors describing receiver array



if nargin < 6
    dogather = 0;
end

% comp. grid
ot = model.o-model.nb(1,:).*model.d;
dt = model.d;
nt = model.n+2*model.nb(1,:);
[zt,xt] = odn2grid(ot,dt,nt);

% data size
nsrc   = size(Q,2);
nrec   = length(model.zrec)*length(model.xrec);
nfreq  = length(model.freq);

% define wavelet
w = exp(1i*2*pi*model.freq*model.t0);
if model.f0
    % Ricker wavelet with peak-frequency model.f0
    w = (model.freq).^2.*exp(-(model.freq/model.f0).^2).*w;
end

% mapping from source/receiver/physical grid to comp. grid
Pr = opKron(opLInterp1D(xt,model.xrec),opLInterp1D(zt,model.zrec));
Ps = opKron(opLInterp1D(xt,model.xsrc),opLInterp1D(zt,model.zsrc));
Px = opKron(opExtension(model.n(2),model.nb(1,2)),opExtension(model.n(1),model.nb(1,1)));
Pe = opKron(opExtension(model.n(2),model.nb(1,2),0),opExtension(model.n(1),model.nb(1,1),0));
% model parameter: slowness [s/m] on computational grid.
mu = Px*m;

% distribute frequencies according to standard distribution
freq = distributed(model.freq);
w    = distributed(w);

if flag==1
    % solve Helmholtz for each frequency in parallel
    spmd
        codistr   = codistributor1d(3,codistributor1d.unsetPartition,[nsrc*nrec,model.nsamples,nfreq]);
        freqloc   = getLocalPart(freq);
        wloc      = getLocalPart(w);
        nfreqloc  = length(freqloc);
        LLloc     = getLocalPart(LL);
        UUloc     = getLocalPart(UU);
        Pploc     = getLocalPart(Pp);
        Qploc     = getLocalPart(Qp);
        Rrloc     = getLocalPart(Rr);
        dHloc     = getLocalPart(dH);
        outputloc = zeros(nsrc*nrec,model.nsamples,nfreqloc);
        input     = reshape(input,prod(model.n),model.nsamples);
        for i = 1:model.nsamples
            for k = 1: nfreqloc
                Qp1       = reshape(Qploc(:,k),prod(nt)*prod(nt),model.nsamples);
                LL1       = reshape(LLloc(:,k),prod(nt)*prod(nt),model.nsamples);
                UU1       = reshape(UUloc(:,k),prod(nt)*prod(nt),model.nsamples);
                Pp1       = reshape(Pploc(:,k),prod(nt)*prod(nt),model.nsamples);
                Rr1       = reshape(Rrloc(:,k),prod(nt)*prod(nt),model.nsamples);
                dH1       = reshape(dHloc(:,k),prod(nt)*prod(nt),model.nsamples);
                Qp        = reshape(Qp1(:,i),prod(nt),prod(nt));
                LL        = reshape(LL1(:,i),prod(nt),prod(nt));
                UU        = reshape(UU1(:,i),prod(nt),prod(nt));
                Pp        = reshape(Pp1(:,i),prod(nt),prod(nt));
                Rr        = reshape(Rr1(:,i),prod(nt),prod(nt));
                dH        = reshape(dH1(:,i),prod(nt),prod(nt));   
                Qk        = wloc(k)*(Ps'*Q);
                U0k       = Qp*(UU\(LL\(Pp*(Rr\(Qk)))));
                Sk        = -(dH*(U0k.*repmat(Px*input(:,i),1,nsrc)));
                U1k       = Qp*(UU\(LL\(Pp*(Rr\(Sk)))));
                outputloc(:,i,k) = vec(Pr*U1k);
            end
        end
        output = codistributed.build(outputloc,codistr,'noCommunication');
    end
    output = vec(output);
else
    spmd
        freqloc   = getLocalPart(freq);
        wloc      = getLocalPart(w);
        nfreqloc  = length(freqloc);
        LLloc     = getLocalPart(LL);
        UUloc     = getLocalPart(UU);
        Pploc     = getLocalPart(Pp);
        Qploc     = getLocalPart(Qp);
        Rrloc     = getLocalPart(Rr);
        dHloc     = getLocalPart(dH);
        outputloc = zeros(prod(model.n),model.nsamples);
        inputloc  = getLocalPart(input);
        inputloc  = reshape(inputloc,[nsrc*nrec,model.nsamples,nfreqloc]);
        for i = 1:model.nsamples
            for k = 1:nfreqloc
                Qp1       = reshape(Qploc(:,k),prod(nt)*prod(nt),model.nsamples);
                LL1       = reshape(LLloc(:,k),prod(nt)*prod(nt),model.nsamples);
                UU1       = reshape(UUloc(:,k),prod(nt)*prod(nt),model.nsamples);
                Pp1       = reshape(Pploc(:,k),prod(nt)*prod(nt),model.nsamples);
                Rr1       = reshape(Rrloc(:,k),prod(nt)*prod(nt),model.nsamples);
                dH1       = reshape(dHloc(:,k),prod(nt)*prod(nt),model.nsamples);
                Qp        = reshape(Qp1(:,i),prod(nt),prod(nt));
                LL        = reshape(LL1(:,i),prod(nt),prod(nt));
                UU        = reshape(UU1(:,i),prod(nt),prod(nt));
                Pp        = reshape(Pp1(:,i),prod(nt),prod(nt));
                Rr        = reshape(Rr1(:,i),prod(nt),prod(nt));
                dH        = reshape(dH1(:,i),prod(nt),prod(nt));               
                Qk        = wloc(k)*(Ps'*Q);
                U0k       = Qp*(UU\(LL\(Pp*(Rr\(Qk)))));
                Sk        = -Pr'*reshape(inputloc(:,i,k),[nrec nsrc]);
                V0k       = Rr'\(Pp'*(LL'\(UU'\(Qp'*Sk))));
                r         = real(sum(conj(U0k).*(dH'*V0k),2));
                outputloc(:,i) = outputloc(:,i) + Pe'*r;
            end
            output = pSPOT.utils.global_sum(outputloc);
        end
    end
        output = output{1};
end
output = vec(output);