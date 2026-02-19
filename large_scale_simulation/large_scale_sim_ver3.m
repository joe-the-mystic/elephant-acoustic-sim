%
% Author: Abhirath Koushik
%
% Brief: Attraction/Repulsion Simulation of Elephant with Poachers,
%        Elephant (Blue circle), Green Zone (attraction), Red Zone
%        (repulsion), Poachers (Magenta moving circles)  
% 
% Revision 1 (11-15-2025): Initial simulation with 1 elephant, 2 Zones and 2 poachers
% Revision 2 (01-22-2026): Large Scale Simulation, added Mic with detection
% states, 5 red zones, 5 elephants, 2 poachers
% Revision 3 (02-19-2026): Mics surround every red zone, 20 Elephants, 10
% Poachers, Live Report of Poached elephants or Poachers Nuetralized
%

clear;
clc;
close all;

% Initialize Random Seed
rng('shuffle');

% -------------------------------------------------------------------------
% 1. CONFIGURATION & SCALING
% -------------------------------------------------------------------------
WIDTH = 600;   
HEIGHT = 600;  
SIDEBAR_W = 220; 

REF_WIDTH = 1000; REF_HEIGHT = 1000;
SF_X = WIDTH / REF_WIDTH;
SF_Y = HEIGHT / REF_HEIGHT;

METERS_PER_PIXEL = 76 / SF_X; 
SPEED_ELEPHANT_MPS = 1.0; 
SPEED_POACHER_MPS = 0.55; 

% -------------------------------------------------------------------------
% 2. PARK BOUNDARY DEFINITION
% -------------------------------------------------------------------------
ref_poly_x = [
    50,   150,  300,  450,  600,  680,  750,  850,  980, ... 
    980,  850,  720,  650,  620,  640,  620,  550,  500, ... 
    450,  380,  350,  350,  320,  250,  200,  100,  50, ...  
    20,   50 
];
ref_poly_y = [
    150,  100,   60,   50,   20,   20,   20,   30,   40, ... 
    120,  140,  140,  300,  400,  500,  650,  800,  900, ... 
    1000,  850,  750,  650,  550,  520,  480,  400,  300, ... 
    280,  150 
];
park_boundary_x = ref_poly_x * SF_X;
park_boundary_y = ref_poly_y * SF_Y;
isInsidePark = @(x, y) inpolygon(x, y, park_boundary_x, park_boundary_y);

% -------------------------------------------------------------------------
% 3. ENVIRONMENT SETUP
% -------------------------------------------------------------------------
% Repulsion Zones (Villages)
repulsors = struct('x', {}, 'y', {}, 'radius', {}, 'name', {});
repulsors(1) = struct('x', 320*SF_X, 'y', 220*SF_Y, 'radius', 40*SF_X, 'name', 'Nola'); 
repulsors(2) = struct('x', 380*SF_X, 'y', 430*SF_Y, 'radius', 30*SF_X, 'name', 'Salo');
repulsors(3) = struct('x', 480*SF_X, 'y', 600*SF_Y, 'radius', 40*SF_X, 'name', 'Bayanga');
repulsors(4) = struct('x', 380*SF_X, 'y', 750*SF_Y, 'radius', 30*SF_X, 'name', 'Lidjombo');
repulsors(5) = struct('x', 190*SF_X, 'y', 120*SF_Y, 'radius', 30*SF_X, 'name', 'Mossipa');

% Attraction Zone (Bai)
attractor.x = 550 * SF_X; 
attractor.y = 550 * SF_Y;
attractor.radius = 25 * SF_X; 
attractor.sensing_range = 80 * SF_X; 

% -------------------------------------------------------------------------
% 4. AGENT INITIALIZATION
% -------------------------------------------------------------------------
% --- ELEPHANTS (20 Total) ---
num_elephants = 20; 
for k = 1:num_elephants
    valid_start = false;
    while ~valid_start
        sx = rand() * WIDTH; sy = rand() * HEIGHT;
        if isInsidePark(sx, sy)
            players(k).x = sx; players(k).y = sy;
            valid_start = true;
        end
    end
    
    players(k).radius = 8 * SF_X; 
    players(k).is_poached = false; 
    players(k).poach_time = -999;
    
    players(k).state = "ROAMING"; 
    players(k).attractorEntryTime = 0;
    players(k).last_visit_time = -999; 
    players(k).vx = 0; players(k).vy = 0; 
    
    valid_target = false;
    while ~valid_target
        tx = rand() * WIDTH; ty = rand() * HEIGHT;
        if isInsidePark(tx, ty)
            players(k).target_x = tx; players(k).target_y = ty;
            valid_target = true;
        end
    end
end

% --- POACHERS (10 Total) ---
num_poachers = 10;
for p = 1:num_poachers
    valid_start = false;
    while ~valid_start
        start_node = randi(length(repulsors));
        sx = repulsors(start_node).x + (rand()-0.5)*(80*SF_X);
        sy = repulsors(start_node).y + (rand()-0.5)*(80*SF_Y);
        d_green = norm([sx-attractor.x, sy-attractor.y]);
        if isInsidePark(sx, sy) && d_green > attractor.radius + 20
            poachers(p).x = sx; poachers(p).y = sy;
            valid_start = true;
        end
    end
    poachers(p).radius = 8 * SF_X;
    poachers(p).target_x = poachers(p).x; poachers(p).target_y = poachers(p).y;
    poachers(p).is_caught = false; 
    poachers(p).caught_time = -999;
end

% -------------------------------------------------------------------------
% 5. SENSOR NETWORK (50 MICS)
% -------------------------------------------------------------------------
mic_specs.range_e = 52 * SF_X;        
mic_specs.range_p = 30 * SF_X;        
mic_specs.threat_dist_px = 60 * SF_X; 

num_mics = 50;
mics = repmat(struct('x',0,'y',0,'active_e',false,'active_p',false,'threat',false), num_mics, 1);
min_spacing = mic_specs.range_p * 1.75; 

ref_mic_coords = [
    200, 130;  270, 200;  200, 270;  130, 200;
    320, 210;  390, 280;  320, 350;  250, 280;
    380, 380;  450, 450;  380, 520;  310, 450;
    480, 530;  550, 600;  480, 670;  410, 600;
    420, 680;  490, 750;  420, 820;  350, 750;
    550, 470;  630, 550;  550, 630;  470, 550;
    300, 120;  400, 140;  500, 120;  600, 110;  700, 100;  800, 110;  900, 140;
    650, 200;  750, 250;  700, 350;  800, 400;  750, 500;  650, 650;
    400, 220;  500, 220;  450, 320;  550, 320;  500, 400;  650, 420;
    200, 350;  250, 450;  280, 550;  350, 650;  450, 850;  500, 750;  350, 850;
];

count = 0;
for i = 1:size(ref_mic_coords, 1)
    mx = ref_mic_coords(i,1) * SF_X; my = ref_mic_coords(i,2) * SF_Y;
    if isInsidePark(mx, my)
        too_close = false;
        for j = 1:count
            if norm([mx - mics(j).x, my - mics(j).y]) < min_spacing, too_close = true; break; end
        end
        if ~too_close, count = count + 1; mics(count).x = mx; mics(count).y = my; end
    end
end

attempts = 0;
while count < num_mics && attempts < 10000
    mx = rand() * WIDTH; my = rand() * HEIGHT;
    if isInsidePark(mx, my)
        too_close = false;
        for j = 1:count
            if norm([mx - mics(j).x, my - mics(j).y]) < min_spacing, too_close = true; break; end
        end
        if ~too_close, count = count + 1; mics(count).x = mx; mics(count).y = my; end
    end
    attempts = attempts + 1;
    if mod(attempts, 1000) == 0, min_spacing = min_spacing * 0.9; end
end
mics = mics(1:count);
num_mics = count;

% -------------------------------------------------------------------------
% 6. VISUALIZATION & UI
% -------------------------------------------------------------------------
h_fig = figure('Name', 'Dzanga Simulation Dashboard', 'Position', [100, 100, WIDTH + SIDEBAR_W + 50, HEIGHT+120]);
set(h_fig, 'MenuBar', 'none', 'ToolBar', 'none', 'Color', [0.15 0.15 0.15]); 

ax = axes('Units', 'pixels', 'Position', [25, 70, WIDTH, HEIGHT]);
hold(ax, 'on'); axis(ax, [0 WIDTH 0 HEIGHT]); set(ax, 'YDir', 'reverse');

try
    img = imread('dzanga_sangha_updated_black.png'); 
    image(ax, 'XData', [0 WIDTH], 'YData', [0 HEIGHT], 'CData', img);
catch
    set(ax, 'Color', [0.1 0.2 0.1]); 
end

% Draw the boundary line
plot(ax, [park_boundary_x, park_boundary_x(1)], [park_boundary_y, park_boundary_y(1)], 'w--', 'LineWidth', 1);

h_slider = uicontrol('Style', 'slider', 'Min', 1, 'Max', 5000, 'Value', 1000, ...
                     'Position', [WIDTH/2 - 100, 20, 200, 20], 'BackgroundColor', [0.3 0.3 0.3]);
h_slider_label = uicontrol('Style', 'text', 'Position', [WIDTH/2 - 100, 45, 200, 20], ...
                           'String', 'Time Lapse: 1000x', 'FontSize', 10, 'FontWeight', 'bold', ...
                           'BackgroundColor', [0.15 0.15 0.15], 'ForegroundColor', [1 1 1]);

% --- LIVE REPORT SIDEBAR ---
h_panel = uipanel('Title', ' LIVE MISSION REPORT ', 'FontSize', 12, 'FontWeight', 'bold', ...
                  'Units', 'pixels', 'Position', [WIDTH + 35, HEIGHT - 200, SIDEBAR_W - 10, 270], ...
                  'BackgroundColor', [0 0 0], 'ForegroundColor', [1 1 1]);

h_report_text = uicontrol('Parent', h_panel, 'Style', 'text', ...
                  'Units', 'normalized', 'Position', [0.05 0.05 0.9 0.9], ...
                  'String', 'Initializing...', 'FontSize', 12, 'HorizontalAlignment', 'left', ...
                  'BackgroundColor', [0 0 0], 'ForegroundColor', [1 1 1]);

% Draw Zones
for r = 1:length(repulsors)
    rectangle(ax, 'Position', [repulsors(r).x-repulsors(r).radius, repulsors(r).y-repulsors(r).radius, repulsors(r).radius*2, repulsors(r).radius*2], ...
              'Curvature', [1 1], 'FaceColor', [1 0 0 0.3], 'EdgeColor', 'none');
          
    text(ax, repulsors(r).x, repulsors(r).y, repulsors(r).name, ...
        'Color', 'w', 'FontSize', 9, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

% Draw Green Zone
rectangle(ax, 'Position', [attractor.x-attractor.radius, attractor.y-attractor.radius, attractor.radius*2, attractor.radius*2], ...
          'Curvature', [1 1], 'FaceColor', [0 1 0 0.3], 'EdgeColor', 'g', 'LineWidth', 2);

for k=1:num_elephants, h_players(k)=plot(NaN,NaN); end
for p=1:num_poachers, h_poachers(p)=plot(NaN,NaN); end
for m=1:num_mics
    h_mics(m) = rectangle(ax, 'Position', [0 0 1 1], 'FaceColor', 'c', 'EdgeColor', 'w');
    h_rings_e(m) = rectangle(ax, 'Position', [0 0 1 1], 'Curvature', [1 1], 'EdgeColor', [0 1 1 0.4], 'LineStyle', '--', 'LineWidth', 1.2);
    h_rings_p(m) = rectangle(ax, 'Position', [0 0 1 1], 'Curvature', [1 1], 'EdgeColor', [1 0.8 0 0.5], 'LineStyle', '-', 'LineWidth', 1.2);
end
h_threat_lines = plot(NaN, NaN, 'r-.', 'LineWidth', 2); 
h_status_text = text(WIDTH/2, 50, '', 'FontSize', 20, 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'BackgroundColor', [0 0 0 0.6], 'Color', [1 1 1]);

% -------------------------------------------------------------------------
% INITIAL RENDER & 10-SECOND COUNTDOWN
% -------------------------------------------------------------------------

% Render the agents and mics in their starting positions
for p=1:num_poachers
    set(h_poachers(p), 'XData', poachers(p).x, 'YData', poachers(p).y, 'Marker', 'o', 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'w', 'MarkerSize', 6);
end
for k=1:num_elephants
    set(h_players(k), 'XData', players(k).x, 'YData', players(k).y, 'Marker', 'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'w', 'MarkerSize', 8*SF_X);
end
for m=1:num_mics
    set(h_mics(m), 'Position', [mics(m).x-3, mics(m).y-3, 6, 6], 'FaceColor', 'c');
    set(h_rings_e(m), 'Position', [mics(m).x-mic_specs.range_e, mics(m).y-mic_specs.range_e, mic_specs.range_e*2, mic_specs.range_e*2]);
    set(h_rings_p(m), 'Position', [mics(m).x-mic_specs.range_p, mics(m).y-mic_specs.range_p, mic_specs.range_p*2, mic_specs.range_p*2]);
end

% Set initial text for the sidebar
init_sidebar_text = sprintf([ ...
    'ELEPHANTS\n', ...
    '--------------\n', ...
    'Total: %d\n', ...
    'Safe/Active: %d\n', ...
    'Poached: 0\n\n\n', ...
    'POACHERS\n', ...
    '--------------\n', ...
    'Total: %d\n', ...
    'Active: %d\n', ...
    'Neutralized: 0'], ...
    num_elephants, num_elephants, num_poachers, num_poachers);
set(h_report_text, 'String', init_sidebar_text);

% Countdown Loop
for cd = 10:-1:1
    if ~ishandle(h_fig), break; end
    set(h_status_text, 'String', sprintf('STARTING IN %d...', cd), 'Color', [1 1 0]);
    drawnow;
    pause(1);
end

% Clear the countdown text if the window is still open
if ishandle(h_fig)
    set(h_status_text, 'String', '');
end

% -------------------------------------------------------------------------
% 7. MAIN LOOP
% -------------------------------------------------------------------------
tic; last_time = toc; current_sim_time = 0; 

while ishandle(h_fig)
    real_dt = toc - last_time; last_time = toc;
    time_multiplier = get(h_slider, 'Value');
    current_sim_time = current_sim_time + real_dt; 
    set(h_slider_label, 'String', sprintf('Time Lapse: %.0fx', time_multiplier));
    
    step_e = (SPEED_ELEPHANT_MPS * time_multiplier * real_dt) / METERS_PER_PIXEL;
    step_p = (SPEED_POACHER_MPS * time_multiplier * real_dt) / METERS_PER_PIXEL;
    
    % --- 1. POACHER MOVEMENT ---
    for p = 1:num_poachers
        if poachers(p).is_caught, continue; end 
        dist = norm([poachers(p).target_x - poachers(p).x, poachers(p).target_y - poachers(p).y]);
        if dist < 10
            valid = false;
            while ~valid
                tx = rand() * WIDTH; ty = rand() * HEIGHT;
                d_green_t = norm([tx - attractor.x, ty - attractor.y]);
                if isInsidePark(tx, ty) && d_green_t > attractor.radius + 20
                    poachers(p).target_x = tx; poachers(p).target_y = ty; valid = true; 
                end
            end
        end
        vec_x = (poachers(p).target_x - poachers(p).x) / dist;
        vec_y = (poachers(p).target_y - poachers(p).y) / dist;
        
        d_green = norm([poachers(p).x - attractor.x, poachers(p).y - attractor.y]);
        if d_green < attractor.radius + 50
            vec_x = vec_x + ((poachers(p).x - attractor.x)/d_green) * 3.0;
            vec_y = vec_y + ((poachers(p).y - attractor.y)/d_green) * 3.0;
        end
        mag = norm([vec_x, vec_y]); if mag > 0, vec_x = vec_x/mag; vec_y = vec_y/mag; end
        nx = poachers(p).x + vec_x * step_p; ny = poachers(p).y + vec_y * step_p;
        
        if isInsidePark(nx, ny)
            poachers(p).x = nx; poachers(p).y = ny;
        else
            valid_bounce = false;
            while ~valid_bounce
                tx = rand() * WIDTH; ty = rand() * HEIGHT;
                d_green_t = norm([tx - attractor.x, ty - attractor.y]);
                if isInsidePark(tx, ty) && d_green_t > attractor.radius + 20
                    poachers(p).target_x = tx; poachers(p).target_y = ty; valid_bounce = true; 
                end
            end
        end
    end
    
    % --- 2. ELEPHANT MOVEMENT ---
    for k=1:num_elephants
        if players(k).is_poached, continue; end 
        dist = norm([players(k).target_x - players(k).x, players(k).target_y - players(k).y]);
        d_bai = norm([players(k).x - attractor.x, players(k).y - attractor.y]);
        
        if players(k).state == "ROAMING"
            if (current_sim_time - players(k).last_visit_time) > 60
                if d_bai < attractor.sensing_range, players(k).state = "SEEKING"; end
            end
        elseif players(k).state == "SEEKING"
            if d_bai < attractor.radius
                players(k).state = "WAITING"; players(k).attractorEntryTime = current_sim_time;
            end
        elseif players(k).state == "WAITING"
            if (current_sim_time - players(k).attractorEntryTime) > 10
                players(k).state = "ROAMING"; players(k).last_visit_time = current_sim_time; 
                valid_exit = false;
                while ~valid_exit
                    tx = rand() * WIDTH; ty = rand() * HEIGHT;
                    if isInsidePark(tx, ty) && norm([tx-attractor.x, ty-attractor.y]) > 200
                        players(k).target_x = tx; players(k).target_y = ty; valid_exit = true;
                    end
                end
            end
        end
        
        if dist < 20 && players(k).state ~= "WAITING"
            valid = false;
            while ~valid
                tx = rand() * WIDTH; ty = rand() * HEIGHT;
                if isInsidePark(tx, ty) && norm([tx-players(k).x, ty-players(k).y]) > 100
                    players(k).target_x = tx; players(k).target_y = ty; valid = true; 
                end
            end
            dist = norm([players(k).target_x - players(k).x, players(k).target_y - players(k).y]);
        end
        
        if players(k).state == "WAITING", des_vx = 0; des_vy = 0; 
        else, des_vx = (players(k).target_x - players(k).x) / dist; des_vy = (players(k).target_y - players(k).y) / dist; end
        
        if players(k).state == "SEEKING"
             des_vx = des_vx + ((attractor.x-players(k).x)/d_bai)*0.8; des_vy = des_vy + ((attractor.y-players(k).y)/d_bai)*0.8;
        end
        
        for r=1:length(repulsors)
            d_rep = norm([players(k).x-repulsors(r).x, players(k).y-repulsors(r).y]);
            if d_rep < repulsors(r).radius + 20
                 des_vx = des_vx + ((players(k).x-repulsors(r).x)/d_rep)*4.0; des_vy = des_vy + ((players(k).y-repulsors(r).y)/d_rep)*4.0;
            end
        end
        
        mag_des = norm([des_vx, des_vy]); if mag_des > 0, des_vx = des_vx/mag_des; des_vy = des_vy/mag_des; end
        players(k).vx = (players(k).vx * 0.95) + (des_vx * 0.05); players(k).vy = (players(k).vy * 0.95) + (des_vy * 0.05);
        mag_curr = norm([players(k).vx, players(k).vy]);
        if mag_curr > 0, players(k).vx = (players(k).vx / mag_curr); players(k).vy = (players(k).vy / mag_curr); end
        
        nx = players(k).x + players(k).vx * step_e; ny = players(k).y + players(k).vy * step_e;
        
        if isInsidePark(nx, ny)
            players(k).x = nx; players(k).y = ny;
        else
            players(k).vx = -players(k).vx; players(k).vy = -players(k).vy; 
            valid_bounce = false;
            while ~valid_bounce
                tx = rand() * WIDTH; ty = rand() * HEIGHT;
                if isInsidePark(tx, ty)
                    players(k).target_x = tx; players(k).target_y = ty; valid_bounce = true; 
                end
            end
        end
    end
    
    % --- 3. SENSOR & INTERCEPTION ---
    threat_lines_x = []; threat_lines_y = [];
    alert_intercepted = false;
    for m = 1:num_mics
        mics(m).active_e = false; mics(m).active_p = false; mics(m).threat = false;
        for k=1:num_elephants
            if norm([players(k).x-mics(m).x, players(k).y-mics(m).y]) < mic_specs.range_e, mics(m).active_e = true; end
        end
        for p=1:num_poachers
            if ~poachers(p).is_caught
                if norm([poachers(p).x-mics(m).x, poachers(p).y-mics(m).y]) < mic_specs.range_p, mics(m).active_p = true; end
            end
        end
        if mics(m).active_e && mics(m).active_p
            for k=1:num_elephants
                if players(k).is_poached, continue; end
                for p=1:num_poachers
                    if poachers(p).is_caught, continue; end 
                    if norm([players(k).x-poachers(p).x, players(k).y-poachers(p).y]) < mic_specs.threat_dist_px
                        mics(m).threat = true; poachers(p).is_caught = true; poachers(p).caught_time = current_sim_time; alert_intercepted = true;
                        threat_lines_x = [threat_lines_x, players(k).x, poachers(p).x, NaN]; threat_lines_y = [threat_lines_y, players(k).y, poachers(p).y, NaN];
                    end
                end
            end
        end
    end
    
    % --- 4. POACHING CHECK ---
    show_poached_alert = false;
    show_caught_alert = false;
    for k = 1:num_elephants
        if players(k).is_poached 
            if (current_sim_time - players(k).poach_time) < 3.0, show_poached_alert = true; end
            continue; 
        end
        for p = 1:num_poachers
            if poachers(p).is_caught 
                if (current_sim_time - poachers(p).caught_time) < 3.0, show_caught_alert = true; end
                continue; 
            end
            if norm([players(k).x-poachers(p).x, players(k).y-poachers(p).y]) < (20*SF_X)
                d_safe = norm([players(k).x - attractor.x, players(k).y - attractor.y]);
                if d_safe > attractor.radius 
                    players(k).is_poached = true; players(k).poach_time = current_sim_time; show_poached_alert = true;
                end
            end
        end
    end
    
    % --- 5. RENDER & UI UPDATE ---
    for p=1:num_poachers
        if poachers(p).is_caught
            set(h_poachers(p), 'XData', poachers(p).x, 'YData', poachers(p).y, 'Marker', 'p', 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'g', 'MarkerSize', 14);
        else
            set(h_poachers(p), 'XData', poachers(p).x, 'YData', poachers(p).y, 'Marker', 'o', 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'w', 'MarkerSize', 6);
        end
    end
    for k=1:num_elephants
        if players(k).is_poached
             set(h_players(k), 'XData', players(k).x, 'YData', players(k).y, 'Marker', 'x', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'MarkerSize', 12, 'LineWidth', 2);
        else
             set(h_players(k), 'XData', players(k).x, 'YData', players(k).y, 'Marker', 'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'w', 'MarkerSize', 8*SF_X);
        end
    end
    for m=1:num_mics
        color = 'c'; if mics(m).active_e, color = 'b'; end; if mics(m).active_p, color = 'r'; end; if mics(m).threat, color = [1 0 0]; end
        set(h_mics(m), 'Position', [mics(m).x-3, mics(m).y-3, 6, 6], 'FaceColor', color);
        set(h_rings_e(m), 'Position', [mics(m).x-mic_specs.range_e, mics(m).y-mic_specs.range_e, mic_specs.range_e*2, mic_specs.range_e*2]);
        set(h_rings_p(m), 'Position', [mics(m).x-mic_specs.range_p, mics(m).y-mic_specs.range_p, mic_specs.range_p*2, mic_specs.range_p*2]);
    end
    set(h_threat_lines, 'XData', threat_lines_x, 'YData', threat_lines_y);
    
    if show_poached_alert
        set(h_status_text, 'String', 'POACHED!', 'Color', [1 0.2 0.2]);
    elseif show_caught_alert
        set(h_status_text, 'String', 'THREAT NEUTRALIZED!', 'Color', [0.2 1 0.2]);
    else
        set(h_status_text, 'String', '');
    end
    
    % --- UPDATE LIVE SIDEBAR REPORT ---
    poached_count = sum([players.is_poached]);
    safe_e = num_elephants - poached_count;
    caught_count = sum([poachers.is_caught]);
    active_p = num_poachers - caught_count;
    
    sidebar_text = sprintf([ ...
        'ELEPHANTS\n', ...
        '--------------\n', ...
        'Total: %d\n', ...
        'Safe/Active: %d\n', ...
        'Poached: %d\n\n\n', ...
        'POACHERS\n', ...
        '--------------\n', ...
        'Total: %d\n', ...
        'Active: %d\n', ...
        'Neutralized: %d'], ...
        num_elephants, safe_e, poached_count, num_poachers, active_p, caught_count);
    
    set(h_report_text, 'String', sidebar_text);
    
    drawnow limitrate;
end
