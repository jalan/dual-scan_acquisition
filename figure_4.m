function figure_4

%% Display parameters for the plots
font_size = 18;
linewidth = 2;

%% Scanning parameters
M = 128;           % samples per scan
d = 10;            % spin density, in arbitrary units
sigma_N = 1;       % noise standard deviation, in arbitrary units
Gamma_min = 0.001; % the minimum HWHM linewidth, in Gauss
scans = 2;         % number of scans

%% Which Gamma_max values to try
Gamma_max_steps = 32;   % how many to try
Gamma_max_first = 0.01; % lowest value for Gamma_max, in Gauss
Gamma_max_last = 2;     % highest value for Gamma_max, in Gauss
Gamma_max = linspace(Gamma_max_first, Gamma_max_last, Gamma_max_steps);

%% How many Gamma values to use in crlb_on_mean_std
Gamma_steps = 32;

%% Bounds for both Delta_B and B_m, in Gauss. very permissive
lower_bound = 0.01;
upper_bound = 100;

%% What program are we using?
is_octave = exist('OCTAVE_VERSION', 'builtin');

%% If using octave, we'll use functions from the optim package
if is_octave
	pkg("load", "optim");
end

%% Preallocate
parameters = zeros(2, scans, length(Gamma_max));
bounds = zeros(size(Gamma_max));

%% Find the best parameters
for j=1:length(Gamma_max)

	% Try many times, since we may have multiple local minima
	initializations = 10;

	% Preallocate
	X_hat = zeros(2, scans, initializations);
	bound = zeros(initializations, 1);

	for i=1:initializations

		% Pick a starting point where I believe a local minimum is. Alternately,
		% you can use a random starting guess, in which case you should also
		% increase the number of initializations above significantly
		%guess = lower_bound + rand(2, 2)*(upper_bound - lower_bound);
		guess = Gamma_max(j)*[1.22 6.46; 2.74 8.99];

		% Create the objective function
		if is_octave % we're using octave
			% X and guess must be vectors!
			guess = guess(:);
			objective = @(X) crlb_on_mean_std([X(1:scans) X(scans+1:end)], ...
				scans, d, sigma_N, M, ...
				Gamma_min, Gamma_max(j), Gamma_steps);
		else % we're using MATLAB
			objective = @(X) crlb_on_mean_std(X, scans, d, sigma_N, M, ...
				Gamma_min, Gamma_max(j), Gamma_steps);
		end

		% Find a local minimum
		if is_octave % we're using octave
			[X_hat_octave, bound(i)] = nonlin_min( ...
				objective,   ... % objective function
				guess,       ... % starting guess
				optimset( ...
					"lbound", ones(2*scans, 1)*lower_bound, ...
					"ubound", ones(2*scans, 1)*upper_bound));
			X_hat(:,:,i) = [X_hat_octave(1:scans) X_hat_octave(scans+1:end)];
		else % we're using MATLAB
			[X_hat(:,:,i), bound(i)] = fmincon( ...
				objective,                   ... % objective function
				guess,                       ... % starting guess
				[], [], [], [],              ... % no complicated constraints
				ones(2, scans)*lower_bound,  ... % lower bounds
				ones(2, scans)*upper_bound); ... % upper bounds
		end

	end

	% Tell us the best result and where it happened
	[best_bound, index] = min(bound);
	best_parameters = X_hat(:,:,index);

	% Sort the scans
	if best_parameters(1,1) > best_parameters(1,2)
		best_parameters = fliplr(best_parameters);
	end

	parameters(:,:,j) = best_parameters;
	bounds(j) = best_bound;

end

%% Extract the parameters we want to plot
B_m1 = zeros(size(Gamma_max));
B_m2 = zeros(size(Gamma_max));
Delta_B1 = zeros(size(Gamma_max));
Delta_B2 = zeros(size(Gamma_max));
B_m1(:) = parameters(1,1,:);
Delta_B1(:) = parameters(2,1,:);
B_m2(:) = parameters(1,2,:);
Delta_B2(:) = parameters(2,2,:);

%% New figure window
figure();

%% One plot with four parameters
hold('on');
set(gca(), 'Fontsize', font_size);
set(gca(), 'Linewidth', linewidth);
plot(Gamma_max, B_m1, '-r', 'Linewidth', linewidth);
plot(Gamma_max, Delta_B1, '--r', 'Linewidth', linewidth);
plot(Gamma_max, B_m2, '-b', 'Linewidth', linewidth);
plot(Gamma_max, Delta_B2, '--b', 'Linewidth', linewidth);
xlim([0 Gamma_max_last]*1.1);
xlabel('\Gamma_m_a_x (G)');
ylabel('(G)');
legend('B_m_,_1', '\Delta_B_,_1', 'B_m_,_2', '\Delta_B_,_2', ...
	'Location', 'Northwest');

%% Save figure as an EPS file
print('-depsc2', [mfilename() '.eps']);

end
