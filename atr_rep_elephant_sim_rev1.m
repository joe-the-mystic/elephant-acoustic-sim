
% Author: Abhirath Koushik
%
% Brief: Attraction/Repulsion Simulation of Elephant with Poachers,
%        Elephant (Blue circle), Green Zone (attraction), Red Zone
%        (repulsion), Poachers (Magenta moving circles)  
% 
% Revision 1 (11-15-2025): Initial simulation with 1 elephant, 2 Zones and 2 poachers
%

% --- Reset and Setup ---
clear;
clc;
close all;

% --- Screen Settings (window width in pixels) ---
WIDTH = 600;
HEIGHT = 400;

% --- Simulation Elements Below ---

% Elephant Herd (blue moving circle)
player.x = WIDTH / 2;
player.y = HEIGHT / 2;
player.radius = 10;
player.speed = 2; % Movement speed in pixels per frame
player.force_strength = 4.0; % Strength of attraction/repulsion forces
player.attractorEntryTime = 0;
player.attractorTimeout = 10; % Time (in sec) elephant stays in green zone before exiting
player.state = "SEEKING"; % Initial state of elephant is searching for attractor (green zone)

% Attractor Zone (Green static circle)
attractor.x = WIDTH * 0.25; 
attractor.y = HEIGHT / 2;
attractor.radius = 100;

% Repulsor Zone (Red static circle)
repulsor.x = WIDTH * 0.75;
repulsor.y = HEIGHT / 2;
repulsor.radius = 100;

% Poacher 1 (Magenta moving circle orbiting Red zone)
poacher1.radius = 8;
poacher1.speed = 0.5; % Movement speed in pixels per frame  
poacher1.jitter_strength = 1.0; 
poacher1.tether_strength = 0.5; 
poacher1.orbit_strength = 2.0;   
poacher1.patrol_radius = repulsor.radius + 15; 
poacher1.x = repulsor.x - poacher1.patrol_radius; % Starts at left of red zone circle
poacher1.y = repulsor.y;                         
poacher1.avoid_radius = 50; 

% Poacher 2 (Magenta moving circle orbiting Green zone)
poacher2.radius = 8;
poacher2.speed = 0.5;
poacher2.jitter_strength = 1.0; 
poacher2.tether_strength = 0.5; 
poacher2.orbit_strength = 2.0;   
poacher2.patrol_radius = attractor.radius + 15; 
poacher2.x = attractor.x + poacher2.patrol_radius; % Starts at right of green zone circle
poacher2.y = attractor.y;                         
poacher2.avoid_radius = 50; 


% --- Colors on the Simulation ---
GREEN_ZONE = [0 1 0 0.2]; 
RED_ZONE = [1 0 0 0.2];
PLAYER_COLOR = 'b';
POACHER_COLOR = 'm';

% --- Initialize Figure ---
h_fig = figure('Name', 'Attraction/Repulsion Simulation of Elephants with Poachers');
set(h_fig, 'MenuBar', 'none', 'ToolBar', 'none');
ax = gca;
hold(ax, 'on');
axis(ax, [0 WIDTH 0 HEIGHT]);
axis(ax, 'equal');
box(ax, 'on');
set(ax, 'XTick', [], 'YTick', []);
set(ax, 'YDir', 'reverse');

img = imread('dzanga_bayanga.png'); % Background Image (can be changed for each simulation cell) 
image(ax, 'XData', [0 WIDTH], 'YData', [0 HEIGHT], 'CData', img);


% --- Initializing Variables for Main Simulation ---
h_attractor = [];
h_repulsor = [];
h_player = [];
h_poacher1 = []; 
h_poacher2 = []; 
h_caught_text = []; 

tic; % Start the master timer
while ishandle(h_fig) % Continue the simulation as long as sim window is open
    
    % Poacher 1 Logic (orbiting Red Zone)
    dist_p1_to_home = norm([poacher1.x - repulsor.x, poacher1.y - repulsor.y]);
    p1_dx = (rand() - 0.5) * poacher1.jitter_strength;
    p1_dy = (rand() - 0.5) * poacher1.jitter_strength;
    if dist_p1_to_home > 0
        rad_vec_x = (poacher1.x - repulsor.x) / dist_p1_to_home;
        rad_vec_y = (poacher1.y - repulsor.y) / dist_p1_to_home;
        tan_vec_x = -rad_vec_y;
        tan_vec_y = rad_vec_x;
        radius_error = poacher1.patrol_radius - dist_p1_to_home;
        p1_dx = p1_dx + rad_vec_x * radius_error * poacher1.tether_strength;
        p1_dy = p1_dy + rad_vec_y * radius_error * poacher1.tether_strength;
        p1_dx = p1_dx + tan_vec_x * poacher1.orbit_strength;
        p1_dy = p1_dy + tan_vec_y * poacher1.orbit_strength;
    end
    p1_magnitude = norm([p1_dx, p1_dy]);
    if p1_magnitude > 0
        p1_dx = (p1_dx / p1_magnitude) * poacher1.speed;
        p1_dy = (p1_dy / p1_magnitude) * poacher1.speed;
    end
    poacher1.x = poacher1.x + p1_dx;
    poacher1.y = poacher1.y + p1_dy;
    poacher1.x = max(poacher1.radius, min(WIDTH - poacher1.radius, poacher1.x));
    poacher1.y = max(poacher1.radius, min(HEIGHT - poacher1.radius, poacher1.y));

    % Poacher 2 Logic (orbiting Green Zone)
    dist_p2_to_home = norm([poacher2.x - attractor.x, poacher2.y - attractor.y]);
    p2_dx = (rand() - 0.5) * poacher2.jitter_strength;
    p2_dy = (rand() - 0.5) * poacher2.jitter_strength;
    if dist_p2_to_home > 0
        rad_vec_x = (poacher2.x - attractor.x) / dist_p2_to_home;
        rad_vec_y = (poacher2.y - attractor.y) / dist_p2_to_home;
        tan_vec_x = -rad_vec_y;
        tan_vec_y = rad_vec_x;
        radius_error = poacher2.patrol_radius - dist_p2_to_home;
        p2_dx = p2_dx + rad_vec_x * radius_error * poacher2.tether_strength;
        p2_dy = p2_dy + rad_vec_y * radius_error * poacher2.tether_strength;
        p2_dx = p2_dx + tan_vec_x * poacher2.orbit_strength;
        p2_dy = p2_dy + tan_vec_y * poacher2.orbit_strength;
    end
    p2_magnitude = norm([p2_dx, p2_dy]);
    if p2_magnitude > 0
        p2_dx = (p2_dx / p2_magnitude) * poacher2.speed;
        p2_dy = (p2_dy / p2_magnitude) * poacher2.speed;
    end
    poacher2.x = poacher2.x + p2_dx;
    poacher2.y = poacher2.y + p2_dy;
    poacher2.x = max(poacher2.radius, min(WIDTH - poacher2.radius, poacher2.x));
    poacher2.y = max(poacher2.radius, min(HEIGHT - poacher2.radius, poacher2.y));

    % Elephant herd (Blue circle) Logic
    currentTime = toc;
    
    % dx and dy below indicate the distance the circle can move in each
    % movement (random movements)   
    dx = (rand() - 0.5) * 4; 
    dy = (rand() - 0.5) * 4; 
    
    % Calculate Distances to Zones and Poachers
    dist_to_attractor = norm([player.x - attractor.x, player.y - attractor.y]);
    dist_to_repulsor = norm([player.x - repulsor.x, player.y - repulsor.y]);
    dist_to_poacher1 = norm([player.x - poacher1.x, player.y - poacher1.y]); 
    dist_to_poacher2 = norm([player.x - poacher2.x, player.y - poacher2.y]); 
    
    % --- State Machine Logic for Attractor ---
    switch player.state
        case "SEEKING" % Indicates movement outside the Zones
            if dist_to_attractor < attractor.radius && dist_to_attractor > 0
                vec_x = (attractor.x - player.x) / dist_to_attractor;
                vec_y = (attractor.y - player.y) / dist_to_attractor;
                dx = dx + vec_x * player.force_strength;
                dy = dy + vec_y * player.force_strength;
                
                player.state = "WAITING";
                player.attractorEntryTime = currentTime;
                fprintf('State: WAITING. Entering Green Zone till Timeout. Timer started.\n');
            end
        
        case "WAITING" % Indicates movement inside the Attractor Green Zone
            if dist_to_attractor > 0
                vec_x = (attractor.x - player.x) / dist_to_attractor;
                vec_y = (attractor.y - player.y) / dist_to_attractor;
                dx = dx + vec_x * player.force_strength;
                dy = dy + vec_y * player.force_strength;
            end
            
            timeInZone = currentTime - player.attractorEntryTime;
            if timeInZone >= player.attractorTimeout
                player.state = "EXITING";
                fprintf('State: EXITING. Timeout reached, now exiting Green Zone.\n');
            end
            
            if dist_to_attractor >= attractor.radius
                player.state = "SEEKING";
                fprintf('State: SEEKING. Drifted out early, timer reset.\n');
            end
        
        case "EXITING" % After Waiting in Green Zone, has to exit out after Timeout
            if dist_to_attractor > 0
                vec_x = (player.x - attractor.x) / dist_to_attractor;
                vec_y = (player.y - attractor.y) / dist_to_attractor;
                dx = dx + vec_x * player.force_strength;
                dy = dy + vec_y * player.force_strength;
            end
            if dist_to_attractor >= (attractor.radius+50)
                player.state = "SEEKKING";
                fprintf('State: SEEKING. Successfully exited.\n');
            end
    end
    

    % --- Repulsion Logic (Red zone) ---
    % Apply repulsion force if elephant is inside red zone
    if dist_to_repulsor < repulsor.radius && dist_to_repulsor > 0
        vec_x = (player.x - repulsor.x) / dist_to_repulsor;
        vec_y = (player.y - repulsor.y) / dist_to_repulsor;
        dx = dx + vec_x * player.force_strength;
        dy = dy + vec_y * player.force_strength;
    end
     
    % --- Repulsion Logic (for Poacher 1) ---
    if dist_to_poacher1 < poacher1.avoid_radius && dist_to_poacher1 > 0
        poacher_force_strength = 0.5; % Poacher force strength is noted to be lesser than elephant force strength
        vec_x = (player.x - poacher1.x) / dist_to_poacher1;
        vec_y = (player.y - poacher1.y) / dist_to_poacher1;
        dx = dx + vec_x * poacher_force_strength;
        dy = dy + vec_y * poacher_force_strength;
    end
    
    % --- Repulsion Logic (for Poacher 2) ---
    if dist_to_poacher2 < poacher2.avoid_radius && dist_to_poacher2 > 0
        poacher_force_strength = 0.5; % Poacher force strength is noted to be lesser than elephant force strength
        vec_x = (player.x - poacher2.x) / dist_to_poacher2;
        vec_y = (player.y - poacher2.y) / dist_to_poacher2;
        dx = dx + vec_x * poacher_force_strength;
        dy = dy + vec_y * poacher_force_strength;
    end
    

    % --- Deciding Elephant Caught Condition ---
    isCaught = false; % Flag to check if caught
    if dist_to_poacher1 < poacher1.avoid_radius
        fprintf('Distance to poacher 1: %.2f\n', dist_to_poacher1);
        if dist_to_poacher1 < 30, isCaught = true; end % Considering 30 as threshold for Elephant caught as of now
    end
    if dist_to_poacher2 < poacher2.avoid_radius 
        fprintf('Distance to poacher 2: %.2f\n', dist_to_poacher2);
        if dist_to_poacher2 < 30, isCaught = true; end % Considering 30 as threshold for Elephant caught as of now
    end
    

    % --- Normalize and Apply Movements ---
    magnitude = norm([dx, dy]);
    if magnitude > 0
        dx = (dx / magnitude) * player.speed;
        dy = (dy / magnitude) * player.speed;
    end

    % Update Elephant Position
    player.x = player.x + dx;
    player.y = player.y + dy;
    
    % Boundary Checks based on Screen sizes
    player.x = max(player.radius, min(WIDTH - player.radius, player.x));
    player.y = max(player.radius, min(HEIGHT - player.radius, player.y));
    

    % --- Delete Previous Frame and Draw New Frame ---
    if ishandle(h_attractor), delete(h_attractor); end
    if ishandle(h_repulsor), delete(h_repulsor); end
    if ishandle(h_player), delete(h_player); end
    if ishandle(h_poacher1), delete(h_poacher1); end 
    if ishandle(h_poacher2), delete(h_poacher2); end 
    if ishandle(h_caught_text), delete(h_caught_text); end 
    
    % Draw Attractor (green zone)
    h_attractor = rectangle(ax, 'Position', [attractor.x - attractor.radius, ...
                                          attractor.y - attractor.radius, ...
                                          attractor.radius * 2, ...
                                          attractor.radius * 2], ...
                                'Curvature', [1 1], ...
                                'FaceColor', GREEN_ZONE, ...
                                'EdgeColor', 'none');
              
    % Draw Repulsor (red zone)
    h_repulsor = rectangle(ax, 'Position', [repulsor.x - repulsor.radius, ...
                                         repulsor.y - repulsor.radius, ...
                                         repulsor.radius * 2, ...
                                         repulsor.radius * 2], ...
                               'Curvature', [1 1], ...
                               'FaceColor', RED_ZONE, ...
                               'EdgeColor', 'none');
    
    % Draw Poacher 1 circle (magenta)
    h_poacher1 = plot(ax, poacher1.x, poacher1.y, 'o', ...
                       'MarkerEdgeColor', POACHER_COLOR, ...
                       'MarkerFaceColor', POACHER_COLOR, ...
                       'MarkerSize', poacher1.radius * 1.5);
                       
    % Draw Poacher 2 circle (magenta)
    h_poacher2 = plot(ax, poacher2.x, poacher2.y, 'o', ...
                       'MarkerEdgeColor', POACHER_COLOR, ...
                       'MarkerFaceColor', POACHER_COLOR, ...
                       'MarkerSize', poacher2.radius * 1.5);

    % Draw Elephant Circle (blue)
    h_player = plot(ax, player.x, player.y, 'o', ...
                       'MarkerEdgeColor', PLAYER_COLOR, ...
                       'MarkerFaceColor', PLAYER_COLOR, ...
                       'MarkerSize', player.radius * 1.5);
                       
   
    % Draw "CAUGHT" text if required based on Flag ---
    if isCaught
        if dist_to_poacher1 < 30
            fprintf('--- CAUGHT by poacher 1! ---\n');
        elseif dist_to_poacher2 < 30
            fprintf('--- CAUGHT by poacher 2! ---\n');
        end
        h_caught_text = text(ax, WIDTH/2, HEIGHT/2, 'CAUGHT!', ...
                             'Color', 'r', 'FontSize', 40, ...
                             'FontWeight', 'bold', ...
                             'HorizontalAlignment', 'center');
    end
    
    drawnow limitrate;
    pause(0.016); 
    
end
disp('Simulation window closed.');
