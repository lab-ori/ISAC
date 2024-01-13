function [uav_init, W_opt, R_opt] = get_init_trajectory_SF(target, num_antenna, num_user, num_target, sensing_th, p_max, scaling, V_max, N, start_x, end_x, uav_y)

    uav_init_tmp = linspace(start_x, end_x, N);
    uav_init = [uav_init_tmp' ones(N, 1) * uav_y];
    R_opt = zeros(num_antenna, num_antenna, N);

    for n = 1:N

        distance_target = zeros(num_target);
        steering_target = zeros(num_antenna, num_target);
        steering_target_her = zeros(num_target, num_antenna);
        
        for j = 1:num_target
            distance_target(j) = get_distance(uav_init(n,:), target(j,:));
            steering_target(:, j) = get_steering(distance_target(j), scaling);
            steering_target_her(j, :) = transpose(conj(steering_target(:, j)));
        end

        cvx_begin
    
            cvx_solver Mosek
    
            variable R_init(num_antenna, num_antenna) complex;
    
            minimize(1)
    
            subject to
    
                R_init == hermitian_semidefinite(num_antenna);
    
                power_constraint = real(trace(R_init));
                power_constraint <= p_max;
    
                for j = 1:num_target
                    sensing_constraint = real(steering_target_her(j,:) * (R_init) * steering_target(:,j));
                    sensing_constraint >= sensing_th * distance_target(j)^2;
                end
    
        cvx_end

        if ~strcmp(cvx_status, 'Solved')
            disp("Infeasible UAV Trajectory");
            uav_init = [];
            break;
        else
            R_opt(:,:,n) = R_init;
        end

    end

    W_opt = zeros(num_antenna, num_antenna, num_user, N);
end