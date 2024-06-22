 classdef Render
    
    properties
        
        multiSampleFrames   = 1;
        texPath             = 'Textures';
        soundPath           = 'Sounds';
        screenAspectRatio;
        screenId;
        isPtbWindowOk       = 0;
        viewPoint           = 1;
        teapotFlag;
        perspectiveAngle    = 55;
        eyeLevel            = -0.55;
        ceilingFlag         = 1;
        skybox;
        skyboxFace          = 1;
        tripwireFlag        = 0;
        nQueue              = 0;
        distalCueFlag       = 1;
        DistalCueName;
        DistalCueTarget;
        distalCueLocation;
        perCueFlag          = 0;
        cueOneProperties;
        cueTwoProperties;
        cueTex;
        displayListOne;
        displayListTwo;
        rectOne;
        rectTwo;
        shaderProgram;
        minReq              = 0.001; % Min intersect to be viewable
    end
    
    properties (SetAccess = protected)
        
        viewportPtr;
        viewportRect;
        texNumId;
        nTex                = 0;
        x0;
        y0;
        nRows;
        nCols;
        newWidth;
        newHeight;
        newHz;
        scaleRatio;
        
        
    end
    
    properties (GetAccess = public, SetAccess = immutable)
        
        AGL;
        GL;
        GLU;
        
        oldWidth    = 1376;
        oldHeight   = 768;
        
    end
    
    
    
    methods
        
        function obj = Render(varargin)
            
            if nargin > 0
                
                if isnumeric(varargin{1})
                    
                    res = varargin{1};
                    
                    obj.newWidth        = res(1);
                    obj.newHeight       = res(2);
                    obj.newHz           = res(3);
                    
                    obj.scaleRatio      = obj.newWidth / obj.oldWidth;
                    
                else
                    
                    error('Invalid spatial resolution parameters');
                    
                end
                
            end
            
            if ispc
                
                if isdeployed
                
                    InitializeMatlabOpenGL_SR(0);
                    
                else
                    
                    InitializeMatlabOpenGL(0);
                    
                end
                
            elseif ismac
                
                InitializeMatlabOpenGL(0);
                
            end
                
            Screen('Preference', 'SuppressAllWarnings', 1);
            Screen('Preference', 'SkipSyncTests', 2);
            Screen('Preference','VisualDebugLevel', 0);
            Screen('Preference', 'Verbosity', 0);
            
            % Get the screen numbers. This gives us a number for each of the screens
            % attached to our computer.
            screensCheck = Screen('Screens');
            
            % To draw we select the maximum of these numbers. So in a situation where we
            % have two screens attached to our monitor we will draw to the external
            % screen.
            screenNumber = max(screensCheck);
            obj.screenId = screenNumber;
            
            % Encapsulate and protect AGL, GL, and GLU constants
            
            % eval('agl = AGL;');
            % obj.AGL = agl;
            eval('gl = GL;');
            obj.GL = gl;
            eval('glul = GLU;');
            obj.GLU = glul;
            
        end
        
        function obj = InitMazeWindow(obj, varargin)
            
            if nargin > 0
                
                obj.perspectiveAngle = varargin{1};
                
            end
            
            if nargin > 1
                
                obj.eyeLevel = varargin{2};
                
            end
            
            if nargin > 2
                
                obj.viewPoint = varargin{3};
                
            end
            
            if obj.viewPoint == 2
                
                obj.teapotFlag = 1;
                obj.ceilingFlag = 0; 
                obj.tripwireFlag = 0;
                
            else
                
                obj.teapotFlag = 0;
                
            end

            if nargin > 3
                
               obj.perCueFlag  = varargin{4};
                
            end
            
            obj.texNumId = zeros(1,100);
            
            obj = OpenPtbWindow(obj);
            obj = InitOpenGl(obj);
            obj = obj.AddTexture(GlTexture(obj.texPath, 'wall.jpg'));
            obj = obj.AddTexture(GlTexture(obj.texPath, 'cheese.bmp'));
            obj = obj.AddTexture(GlTexture(obj.texPath, 'tripwire.jpg'));
            obj = obj.AddTexture(GlTexture(obj.texPath, 'ground.jpg'));


            % Skybox texture loading
            
            skyboxSet = ["dust" "haze" "humble" "quirk" "skybox" "trance" "valley"];
            
            box = skyboxSet(5);
            
            obj = obj.AddTextureSkybox(GlTexture(obj.texPath, sprintf('Skyboxes\\%s\\%s_rt.jpg', box, box)));
            obj = obj.AddTextureSkybox(GlTexture(obj.texPath, sprintf('Skyboxes\\%s\\%s_lf.jpg', box, box)));
            obj = obj.AddTextureSkybox(GlTexture(obj.texPath, sprintf('Skyboxes\\%s\\%s_up.jpg', box, box)));
            obj = obj.AddTextureSkybox(GlTexture(obj.texPath, sprintf('Skyboxes\\%s\\%s_dn.jpg', box, box)));
            obj = obj.AddTextureSkybox(GlTexture(obj.texPath, sprintf('Skyboxes\\%s\\%s_ft.jpg', box, box)));
            obj = obj.AddTextureSkybox(GlTexture(obj.texPath, sprintf('Skyboxes\\%s\\%s_bk.jpg', box, box)));
            
            % Distal feature (moon)
            if obj.distalCueFlag
                obj = obj.AddTextureDistalCue('moon.jpg',  obj.viewportPtr);
            end

        end
        
        function obj = OpenPtbWindow(obj)
            
            % Psychtoolbox stuff
            AssertOpenGL;
            
            oldRes = Screen('Resolution', obj.screenId);
            
            if ispc
                
                if (oldRes.width == obj.newWidth) && (oldRes.height== obj.newHeight) && (oldRes.hz== obj.newHz)
                    
                    switchResFlag = 0;
                    
                else
                    
                    switchResFlag = 1;
                    res = Screen('Resolutions', obj.screenId);
                    resIndex = find( ([res(:).width] == obj.newWidth) & ([res(:).height] == obj.newHeight) & ([res(:).hz] == obj.newHz) & ([res(:).pixelSize] == 32) );
                    
                end
                
            elseif ismac
                
                if (oldRes.width == obj.newWidth) && (oldRes.height== obj.newHeight)
                    
                    switchResFlag = 0;
                    
                else
                    
                    switchResFlag = 1;
                    res = Screen('Resolutions', obj.screenId);
                    resIndex = find( ([res(:).width] == obj.newWidth) & ([res(:).height] == obj.newHeight) & ([res(:).pixelSize] == 24) );
                    
                end
                
                
            else
                
                error('Unknown platform');
                
            end
            
            if switchResFlag
                
                if isempty(resIndex)
                    
                    error('Cannot find resolution');
                    
                else
                    
                    SetResolution(obj.screenId, res(resIndex));
                    
                end
                
            end
            
            [windowPtr, windowRect] = Screen('OpenWindow', obj.screenId, 0);
            % [windowPtr, windowRect] = Screen('OpenWindow', obj.screenId, 0, [], [], [], 0, obj.multiSampleFrames);
            obj.viewportPtr = windowPtr;
            obj.viewportRect = windowRect;
            [X0, Y0] = RectCenter(windowRect);
            obj.x0 = X0;
            obj.y0 = Y0;
            
            Screen('TextSize', obj.viewportPtr, 24);
            Screen('TextStyle', obj.viewportPtr, 0);
            Screen('TextFont', obj.viewportPtr, 'Arial');
            Screen('TextColor', obj.viewportPtr, [127 127 127]);
            
            obj.nRows = obj.viewportRect(3);
            obj.nCols = obj.viewportRect(4);
            obj.screenAspectRatio = obj.viewportRect(4)/obj.viewportRect(3);
            HideCursor;
            Screen('Flip', obj.viewportPtr);
            obj.isPtbWindowOk = 1;
            
        end
        
        function wallArray = AssignTexIdToWall(obj, wallArray, textureIndex)
            
            for wallIndex = 1:wallArray.nWalls
                
                wallArray.walls(wallIndex).glTextureId = obj.texNumId(textureIndex);
                
            end
            
        end
        
        
        function obj = AddTexture(obj, texObj)
            
            if ~isa(texObj, 'GlTexture')
                
                error('AddTexture needs a GlTexture object');
                
            end
            
            obj.nTex = obj.nTex + 1;
            texIndex = obj.nTex;
            
            while texIndex > numel(obj.texNumId)
                
                obj.texNumId = [obj.texNumId zeros(1, 100)];
                
            end
            
            obj.texNumId(texIndex) = glGenTextures(1);
            
            glBindTexture(obj.GL.TEXTURE_2D, obj.texNumId(texIndex));
            glTexImage2D(obj.GL.TEXTURE_2D, 0, obj.GL.RGB, texObj.nRows, texObj.nCols, 0, obj.GL.RGB, obj.GL.UNSIGNED_BYTE, texObj.pixels);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_WRAP_S,obj.GL.REPEAT);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_WRAP_T,obj.GL.REPEAT);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_MAG_FILTER,obj.GL.LINEAR);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_MIN_FILTER,obj.GL.NEAREST_MIPMAP_LINEAR);
            glGenerateMipmap(obj.GL.TEXTURE_2D);
            
        end

          %Banki - Texture mapping for 3D Skybox feature
        function obj = AddTextureSkybox(obj, texObj)

            if ~isa(texObj, 'GlTexture')
                
                error('AddTexture needs a GlTexture object');
                
            end
            
            obj.nTex = obj.nTex + 1;
            texIndex = obj.nTex;
            
            while texIndex > numel(obj.texNumId)
                
                obj.texNumId = [obj.texNumId zeros(1, 100)];
                
            end
            
            obj.texNumId(texIndex) = glGenTextures(1);
            
            
            glBindTexture(obj.GL.TEXTURE_2D, obj.texNumId(texIndex));
            glTexImage2D(obj.GL.TEXTURE_2D, 0, obj.GL.RGB, texObj.nRows, texObj.nCols, 0, obj.GL.RGB, obj.GL.UNSIGNED_BYTE, texObj.pixels);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_WRAP_S,obj.GL.CLAMP_TO_EDGE);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_WRAP_T,obj.GL.CLAMP_TO_EDGE);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_WRAP_R,obj.GL.CLAMP_TO_EDGE);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_MAG_FILTER,obj.GL.LINEAR);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_MIN_FILTER,obj.GL.LINEAR);
            
        end
        
         function obj = AddTexturePerCue(obj, texObjOne, texObjTwo)
            
            if ~isa(texObjOne, 'GlTexture')
                
                error('AddTexture for object one needs a GlTexture object');
                
            elseif ~isa(texObjTwo, 'GlTexture')
                
                error('AddTexture for object two needs a GlTexture object');
            end
            %{
            if numel(obj.cueTex) >= 2
            
                n = numel(obj.cueTex) + 1;
                
            else
                
                n = 1;
          
            end
            %}
            n = 1;
            
            obj.cueTex(n) = glGenTextures(1);
            
            glBindTexture(obj.GL.TEXTURE_2D, obj.cueTex(n));
            glTexImage2D(obj.GL.TEXTURE_2D, 0, obj.GL.RGB, texObjOne.nRows, texObjOne.nCols, 0, obj.GL.RGB, obj.GL.UNSIGNED_BYTE, texObjOne.pixels);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_WRAP_S,obj.GL.CLAMP_TO_EDGE);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_WRAP_T,obj.GL.CLAMP_TO_EDGE);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_WRAP_R,obj.GL.CLAMP_TO_EDGE);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_MAG_FILTER,obj.GL.LINEAR);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_MIN_FILTER,obj.GL.LINEAR);
            glGenerateMipmap(obj.GL.TEXTURE_2D);
            
            obj.cueTex(n + 1) = glGenTextures(1);
             
            glBindTexture(obj.GL.TEXTURE_2D, obj.cueTex(n + 1));
            glTexImage2D(obj.GL.TEXTURE_2D, 0, obj.GL.RGB, texObjTwo.nRows, texObjTwo.nCols, 0, obj.GL.RGB, obj.GL.UNSIGNED_BYTE, texObjTwo.pixels);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_WRAP_S,obj.GL.CLAMP_TO_EDGE);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_WRAP_T,obj.GL.CLAMP_TO_EDGE);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_WRAP_R,obj.GL.CLAMP_TO_EDGE);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_MAG_FILTER,obj.GL.LINEAR);
            glTexParameterfv(obj.GL.TEXTURE_2D,obj.GL.TEXTURE_MIN_FILTER,obj.GL.LINEAR);
            glGenerateMipmap(obj.GL.TEXTURE_2D);

        end
     
        function obj = AddTextureDistalCue(obj, textFileName, window)

            % Load texture
            image = imread(textFileName);
            [s1, ~, ~] = size(image);
            image = im2double(image(1:s1, 1:s1, :));
            
            % Convert to a texture for PTB drawing (orientation needs changing for
            % rendering)
            imageFlipped = rot90(flipud(image));
            modelTexture = Screen('MakeTexture', window, imageFlipped, [], 1, 2);
            
            % Get the information we need about the texture
            [imw, imh] = Screen('WindowSize', modelTexture);
            [textureName, targetFront, ~, ~] = Screen('GetOpenGLTexture', window, modelTexture, imh, imw);
            
            %Create global attributes
            obj.DistalCueName = textureName;
            obj.DistalCueTarget = targetFront;
            obj.distalCueLocation = round(3 * rand() + 1); % Randomly selects between 1 - 4 distal locations
            

            % Bind our texture and setup filtering to allow nice presentation of our
            % texture
            glBindTexture(targetFront, textureName);
            glGenerateMipmapEXT(targetFront); 
            
            glTexParameterf(targetFront, obj.GL.TEXTURE_MAG_FILTER, obj.GL.LINEAR);
            glTexParameterf(targetFront, obj.GL.TEXTURE_MIN_FILTER, obj.GL.LINEAR_MIPMAP_LINEAR);
            
            % Allow the texture and lighting to interact
            glTexEnvfv(obj.GL.TEXTURE_ENV, obj.GL.TEXTURE_ENV_MODE, obj.GL.MODULATE);
            
            % This gives nice texture rendering without artifacts
            maxAnisotropy = glGetFloatv(obj.GL.MAX_TEXTURE_MAX_ANISOTROPY_EXT);
            glTexParameterf(targetFront, obj.GL.TEXTURE_MAX_ANISOTROPY_EXT, maxAnisotropy);
            
            % Clamping behaviour shall be a cyclic repeat:
            glTexParameteri(targetFront, obj.GL.TEXTURE_WRAP_S, obj.GL.REPEAT);
            glTexParameteri(targetFront, obj.GL.TEXTURE_WRAP_T, obj.GL.REPEAT);
                        
        end

        function obj = loadPerCue(obj, objTexPath, cueProperties)
             % Periperhal Queue
            if obj.perCueFlag
                % load object
                obj.cueOneProperties = LoadOBJFileV2(cueProperties.obj);
                obj.cueTwoProperties = LoadOBJFileV2(cueProperties.objTwo);
                
                % Load object textures
                obj = obj.AddTexturePerCue(GlTexture(objTexPath, cueProperties.tex), GlTexture(objTexPath, cueProperties.texTwo));
                
                % Potential future incorporations of normal textures
                %{
                if isfield(cueProperties, 'normal') && isfield(cueProperties, 'normalTwo')
                    
                     % Load normal textures
                     obj = obj.AddTexturePerCue(GlTexture(objTexPath, cueProperties.normal), GlTexture(objTexPath, cueProperties.normalTwo));
                     
                     shaderpath = 'Objects/Shaders/';
                     obj.shaderProgram = LoadGLSLProgramFromFiles([shaderpath 'object_shader'],1); 

                     gluErrorString

                     % Activate program:
                     glUseProgram(obj.shaderProgram);

                     colorTextureLoc = glGetUniformLocation(obj.shaderProgram, 'colorTexture');
                     normalMapLoc = glGetUniformLocation(obj.shaderProgram, 'normalMap');
                     glUniform1i(colorTextureLoc, 0); % Texture unit 0 for color texture
                     glUniform1i(normalMapLoc, 1); % Texture unit 1 for normal map
                     
                else
                    
                    obj.cueTex(3) = -1;
                    obj.cueTex(4) = -1;
                end
                %}
                
                % Build the display list
                obj.displayListOne = glGenLists(1);
                glNewList(obj.displayListOne, obj.GL.COMPILE);       
                obj = obj.renderPerCue(obj.cueOneProperties{1}, cueProperties.x(1), cueProperties.y(1), cueProperties.scale(1), cueProperties.rot(1), obj.cueTex(1));
                glEndList;
                
                obj.displayListTwo = glGenLists(1);
                glNewList(obj.displayListTwo, obj.GL.COMPILE);       
                obj = obj.renderPerCue(obj.cueTwoProperties{1}, cueProperties.x(2), cueProperties.y(2), cueProperties.scale(2), cueProperties.rot(2), obj.cueTex(2));
                glEndList;
            end
        end
        
        function obj = InitOpenGl(obj)
            
            if isempty(obj.viewportPtr)
                
                error('A PTB window must be opened prior to OpenGL initialization');
                
            end
            
            Screen('BeginOpenGL', obj.viewportPtr);
            glShadeModel(obj.GL.FLAT);
            glEnable(obj.GL.DEPTH_TEST);
            glPixelStorei(obj.GL.UNPACK_ALIGNMENT, 1);
            
            glEnable(obj.GL.LIGHTING);
            glEnable(obj.GL.LIGHT0);
            glLightModelfv(obj.GL.LIGHT_MODEL_TWO_SIDE, obj.GL.TRUE);
            glMaterialfv(obj.GL.FRONT_AND_BACK,obj.GL.AMBIENT, [1 1 1 1]);
            glMaterialfv(obj.GL.FRONT_AND_BACK,obj.GL.DIFFUSE, [1 1 1 1]);
            
            glEnable(obj.GL.TEXTURE_2D);
            
            glClearColor(0,0,0,0);
            
            glMatrixMode(obj.GL.PROJECTION);
            glLoadIdentity();
            gluPerspective(obj.perspectiveAngle, 1/obj.screenAspectRatio, 0.08, 100.0);
            glClearDepth(1.0);
            glMatrixMode(obj.GL.MODELVIEW);
            glLoadIdentity();
            glLightfv(obj.GL.LIGHT0, obj.GL.POSITION, [ 0 4 0 1 ]);
            glLightfv(obj.GL.LIGHT0, obj.GL.DIFFUSE, [ .75 .75 .75 1 ]);
            glLightfv(obj.GL.LIGHT0, obj.GL.AMBIENT, [ .25 .25 .25 1 ]);
            
            % Set uniforms and attributes, and then render your geometry

            if obj.viewPoint == 1
                
                glRotatef(90, 0, 1, 0);
                glTranslatef(0, obj.eyeLevel, 0);
                
            elseif obj.viewPoint == 2
                
                glTranslatef(0, 0, -6);
                glRotatef(90, 1, 0, 0);
                
            end
            
            Screen('EndOpenGL', obj.viewportPtr);
            
        end
        
        
        function UpdateDisplay(obj, player, maze, ipClient)
            
            Screen('BeginOpenGL', obj.viewportPtr);
            glClear;
            glTexEnvf(obj.GL.TEXTURE_ENV, obj.GL.TEXTURE_ENV_MODE, obj.GL.REPLACE);
            
            if obj.viewPoint == 2
                
                if obj.teapotFlag
                    
                    glBindTexture(obj.GL.TEXTURE_2D, 0);
                    glMaterialfv(obj.GL.FRONT_AND_BACK,obj.GL.AMBIENT, [.25 1 .3 1]);
                    glMaterialfv(obj.GL.FRONT_AND_BACK,obj.GL.DIFFUSE, [.25 1 .3 1]);
                    glutSolidTeapot(player.bodyRadius);
                    
                end
                
            end
            
            % Rotate and translate world
            glPushMatrix();
            glRotatef(-player.heading, 0, 1, 0);
            glRotatef(180, 0, 1, 0);
            glTranslatef(-player.nextPos(1), 0, -player.nextPos(2));
            
            % Draw ground
            glBindTexture(obj.GL.TEXTURE_2D, obj.texNumId(4));
            glBegin(obj.GL.QUADS);
            glTexCoord2f(0.0, 0.0); glVertex3f(10, 0.0, -10);
            glTexCoord2f(0.0, 4); glVertex3f(10, 0.0, 10);
            glTexCoord2f(4, 4); glVertex3f(-10, 0.0, 10);
            glTexCoord2f(4, 0.0); glVertex3f(-10, 0.0, -10);
            glEnd;
            
            %   Draw ceiling
            if obj.ceilingFlag

                l = 30; % length
                
                % Top
                glBindTexture(obj.GL.TEXTURE_2D, obj.texNumId(7));
                glBegin(obj.GL.QUADS);
                glTexCoord2f(0.0, 0.0); glVertex3f(-l, l/2, -l);
                glTexCoord2f(0.0, 1); glVertex3f(-l, l/2, l);
                glTexCoord2f(1, 1); glVertex3f(l, l/2, l);
                glTexCoord2f(1, 0.0); glVertex3f(l, l/2, -l);
                glEnd;

                 % Right sky wall
                glBindTexture(obj.GL.TEXTURE_2D, obj.texNumId(5));
                glBegin(obj.GL.QUADS);
                glTexCoord2f(0.0, 0.0); glVertex3f(-l, -l/2, -l);  
                glTexCoord2f(0.0, 1); glVertex3f(-l, l/2, -l);

                glTexCoord2f(1, 1); glVertex3f(l, l/2, -l);
                glTexCoord2f(1, 0.0); glVertex3f(l, -l/2, -l);
                glEnd;
                
                % Left wall
                glBindTexture(obj.GL.TEXTURE_2D, obj.texNumId(6));
                glBegin(obj.GL.QUADS);
                glTexCoord2f(0.0, 0.0); glVertex3f(l, -l/2, l);
                glTexCoord2f(0.0, 1); glVertex3f(l, l/2, l);

                glTexCoord2f(1, 1); glVertex3f(-l, l/2, l);
                glTexCoord2f(1, 0.0); glVertex3f(-l, -l/2, l);
                glEnd;

                 % Front sky wall
                glBindTexture(obj.GL.TEXTURE_2D, obj.texNumId(9));
                glBegin(obj.GL.QUADS);
                glTexCoord2f(0.0, 0.0); glVertex3f(l, -l/2, -l);  
                glTexCoord2f(0.0, 1); glVertex3f(l, l/2, -l);

                glTexCoord2f(1, 1); glVertex3f(l, l/2, l);     
                glTexCoord2f(1, 0.0); glVertex3f(l, -l/2, l);
                glEnd;
                
                % Back sky wall
                glBindTexture(obj.GL.TEXTURE_2D, obj.texNumId(10));
                glBegin(obj.GL.QUADS);
                glTexCoord2f(0.0, 0.0); glVertex3f(-l, -l/2, l);  
                glTexCoord2f(0.0, 1); glVertex3f(-l, l/2, l);

                glTexCoord2f(1, 1); glVertex3f(-l, l/2, -l);
                glTexCoord2f(1, 0.0); glVertex3f(-l, -l/2, -l);
                glEnd;

                
                                                             
            end
            
            % Draw regular walls
            glBindTexture(obj.GL.TEXTURE_2D, obj.texNumId(1));
            glBegin(obj.GL.QUADS);
            for wallIndex = 1:maze.nNormalWalls
                
                thisWall = maze.normalWallArray(wallIndex);
                
                glTexCoord2f(0.0, 0.0); glVertex3f(thisWall.p1(1), 0.0, thisWall.p1(2));
                glTexCoord2f(0.0, 1.0); glVertex3f(thisWall.p1(1), 0.5, thisWall.p1(2));
                
                glTexCoord2f(thisWall.norm, 1.0); glVertex3f(thisWall.p2(1), 0.5, thisWall.p2(2));
                glTexCoord2f(thisWall.norm, 0.0); glVertex3f(thisWall.p2(1), 0.0, thisWall.p2(2));
                
            end
            glEnd;
            
            % Draw target walls
            glBindTexture(obj.GL.TEXTURE_2D, obj.texNumId(2));
            glBegin(obj.GL.QUADS);
            for wallIndex = 1:maze.nTargetWalls
                
                thisWall = maze.targetWallArray(wallIndex);
                
                glTexCoord2f(0.0, 0.0); glVertex3f(thisWall.p1(1), 0.0, thisWall.p1(2));
                glTexCoord2f(0.0, 1.0); glVertex3f(thisWall.p1(1), 0.5, thisWall.p1(2));
                glTexCoord2f(1.0, 1.0); glVertex3f(thisWall.p2(1), 0.5, thisWall.p2(2));
                glTexCoord2f(1.0, 0.0); glVertex3f(thisWall.p2(1), 0.0, thisWall.p2(2));
                
            end
            glEnd;

            if obj.tripwireFlag
                
                % Draw tripwires
                glBindTexture(obj.GL.TEXTURE_2D, obj.texNumId(3));
                glBegin(obj.GL.QUADS);
                for wallIndex = 1:maze.nTripWires
                      
                    thisWall = maze.tripWireArray(wallIndex);
                    
                    glTexCoord2f(0.0, 0.0); glVertex3f(thisWall.p1(1), 0.0, thisWall.p1(2));
                    glTexCoord2f(0.0, 1.0); glVertex3f(thisWall.p1(1), 0.5, thisWall.p1(2));
                    
                    glTexCoord2f(thisWall.norm, 1.0); glVertex3f(thisWall.p2(1), 0.5, thisWall.p2(2));
                    glTexCoord2f(thisWall.norm, 0.0); glVertex3f(thisWall.p2(1), 0.0, thisWall.p2(2));
                    
                end
                glEnd;
                
            end

            if obj.distalCueFlag

                % Number of slices that we wil use on our sphere (higher gives a smoother
                % surface)
                numSlices = 1000;
                
                % Sphere height
                height = 6;
                
                % Enable the loaded model texture
                glEnable(obj.DistalCueTarget);

                % Render the sphere with a local translation that's relative to the global translation
                glPushMatrix;

                 % Translate the sphere to the desired location
                location = obj.distalCueLocation;
                glTranslatef(maze.distalCue.x(location), height, maze.distalCue.y(location));

                %Draw Distall Queue
                glBindTexture(obj.DistalCueTarget, obj.DistalCueName);
                theSphere = gluNewQuadric;
                gluQuadricTexture(theSphere, obj.GL.TRUE);
                sphereRadius = 1.25;
                gluSphere(theSphere, sphereRadius, numSlices, numSlices);

                % Restore the transformation state
                glPopMatrix;
                
                sphereCenter = [maze.distalCue.x(location), height, maze.distalCue.y(location)];
                
                %Building bounding box for distal queue to record screen
                %coordinates
                box = [
                    sphereCenter(1)-sphereRadius,  sphereCenter(2)+sphereRadius, sphereCenter(3)+sphereRadius;
                    sphereCenter(1)+sphereRadius,  sphereCenter(2)+sphereRadius, sphereCenter(3)+sphereRadius;
                    sphereCenter(1)-sphereRadius,  sphereCenter(2)+sphereRadius, sphereCenter(3)-sphereRadius;
                    sphereCenter(1)+sphereRadius,  sphereCenter(2)+sphereRadius, sphereCenter(3)-sphereRadius;
                    sphereCenter(1)-sphereRadius,  sphereCenter(2)-sphereRadius, sphereCenter(3)+sphereRadius;
                    sphereCenter(1)+sphereRadius,  sphereCenter(2)-sphereRadius, sphereCenter(3)+sphereRadius;
                    sphereCenter(1)-sphereRadius,  sphereCenter(2)-sphereRadius, sphereCenter(3)-sphereRadius;
                    sphereCenter(1)+sphereRadius,  sphereCenter(2)-sphereRadius, sphereCenter(3)-sphereRadius
                    ]';
                
                X = zeros(1,8);
                Y = zeros(1,8);
                Z = zeros(1,8);
                
                viewport = glGetIntegerv(obj.GL.VIEWPORT);
                modelView = glGetDoublev(obj.GL.MODELVIEW_MATRIX);
                projectionView = glGetDoublev(obj.GL.PROJECTION_MATRIX);
                 
                for i = 1:size(box, 2)
                 
                 [X(i), Y(i), Z(i)] = gluProject(box(1,i), box(2,i), box(3,i),...
                     modelView, projectionView, viewport);
                 
                end
                
    %             obj = obj.drawBoundingBox(box);
                
                 xMin = min(X);
                 yMin = min(Y);
                 xMax = max(X);
                 yMax = max(Y);
                 zMin = min(Z);
                 
                % Adjust Y to match OpenGL coordinate system
                yMin = double(viewport(4)) - yMin;
                yMax = double(viewport(4)) - yMax;

                % Normailize values for gazepoint ((0,0) Top left, (1,1) Bottom
                % right)
                xMin = xMin / double(viewport(3));
                xMax = xMax / double(viewport(3));
                
                % Because of caretian plan. Y min is max while Y max is min
                tempyMin = yMin;
                yMin = yMax / double(viewport(4));
                yMax = tempyMin / double(viewport(4));
            
                % Check if queue is on screen (viewable)
                onScreen = false;

                xDif = xMax - xMin;
                yDif = yMax - yMin;

                queueRect = [xMin xMax xDif yDif];
                
                screenRect = [0 0 1.0 1.0];
                                
                intersect = rectint(queueRect, screenRect);
                
                minVisibility = (xDif * yDif * obj.minReq);
                
                if minVisibility < intersect && intersect <= 1 && zMin < 1
                    
                    onScreen = true;
                    
                end
                
%                  [collisionFlag, ~] = maze.CollisionCheck(player);
%                  
%                  if collisionFlag == 1
%                      fprintf('Collision\n');
%                  end

                distalCue = [sphereCenter(1), sphereCenter(3)];
                
                blocked = Occlusion.IsMoonBlocked(player, distalCue, maze.normalWallArray, obj.eyeLevel, sphereCenter(2), 0.5);
                 
                if ipClient.client ~= -1
                    
                    gap = '0;';
                        
                    if onScreen && ~blocked
                        
                        ipClient.gazePointSTR.DistalXMin =  strcat(num2str(xMin),';');
                        ipClient.gazePointSTR.DistalXMax =  strcat(num2str(xMax),';');
                        ipClient.gazePointSTR.DistalYMin =  strcat(num2str(yMin),';');
                        ipClient.gazePointSTR.DistalYMax =   strcat(num2str(yMax),';');      
                        
                    else
                        
                        ipClient.gazePointSTR.DistalXMin = gap;
                        ipClient.gazePointSTR.DistalXMax = gap;
                        ipClient.gazePointSTR.DistalYMin = gap;
                        ipClient.gazePointSTR.DistalYMax = gap;

                    end
                end

            end

            if obj.perCueFlag
                
                if ~(strcmp(maze.perCue.obj,'NA'))
                    
                    % Set whether to draw bounding boxes for objects
                    drawBox = true;
                    
                    visible = [0 0];
                    
                    minMaxLimits = zeros(2,5);
                    
                    %----------------------------------Proximal QUE 1------------------------------------------------%

                     glPushMatrix;
                         
                     % Run call list code to render object
                     glCallList(obj.displayListOne);
                        
                     %------------BoundedBox Setup----------------
                     boxOne = BoundingBox(obj, obj.cueOneProperties{1}, maze.perCue.scale(1));
                     [boundingBoxOne, minMax] = boxOne.BoundBoxInitialize();
                                          
                     % Check if bounding box is on screen 
                     [onScreen, ~] = boxOne.IsBoundingBoxVisible(maze.normalWallArray,  maze.perCue.x(1), maze.perCue.y(1) ,player, obj.minReq, minMax); 
                     
                     minMaxLimits(1, :) = minMax;
                     visible(1) = onScreen;
                     
                     if drawBox == true
                          
                         glColor3f(1, 0, 0);
                         obj = obj.drawBoundingBox(boundingBoxOne);
                         
                     end
                      
                     glPopMatrix;

                      %----------------------------------Proximal QUE 2------------------------------------------------%
                      
                     glPushMatrix;
 
                     glCallList(obj.displayListTwo);

                     %------------BoundedBox Setup----------------
                     boxTwo = BoundingBox(obj, obj.cueTwoProperties{1}, maze.perCue.scale(2));
                     [boundingBoxTwo, minMaxTwo] = boxTwo.BoundBoxInitialize();
                     
                     % Check if bounding box is on screen 
                     [onScreenTwo, ~] = boxTwo.IsBoundingBoxVisible(maze.normalWallArray,  maze.perCue.x(2), maze.perCue.y(2) ,player, obj.minReq, minMaxTwo); 
                     
                     minMaxLimits(2, :) = minMaxTwo;
                     visible(2) = onScreenTwo;
                      
                      % Draw bounding box
                      if drawBox == true
                          
                          glColor3f(1, 0, 0);
                          obj = obj.drawBoundingBox(boundingBoxTwo);
                          
                      end
                      
                     glPopMatrix;
                     
                     % Fill values retrevied boundingbox visible function
                     if ipClient.client ~= -1 
                         
                      gap = '0;';
                      
                      names = ipClient.names(5:12);
                      names = reshape(names, [4,2]);
                      
                      % Load values for sending to round cube
                      for cue = 1:numel(visible)
                          
                          % Send the bounding box limit values
                          if visible(cue)

                              for index = 1:numel(names(:, 1))

                                  ipClient.gazePointSTR.(names{index , cue}) =  strcat(num2str(minMaxLimits(cue, index)), ';');
                                  
                              end
                              
                          else
                              % send 0
                              for index = 1:numel(names(:, 1))

                                  ipClient.gazePointSTR.(names{index , cue}) =  gap;
                                  
                              end
                              
                          end
                          
                      end
                      
                     end
                 
                end
                
            end
           
            % Send to gazepoint if running eyetracker
              if ipClient.client ~= -1 

                  gpStr = ipClient.gazePointSTR;
                  
                  strLog = strcat(...
                      gpStr.XMin, gpStr.CueOneXMin,...
                      gpStr.XMax, gpStr.CueOneXMax,...
                      gpStr.YMin, gpStr.CueOneYMin,...
                      gpStr.YMax, gpStr.CueOneYMax,...
                      gpStr.XMin, gpStr.CueTwoXMin,...
                      gpStr.XMax, gpStr.CueTwoXMax,...
                      gpStr.YMin, gpStr.CueTwoYMin,...
                      gpStr.YMax, gpStr.CueTwoYMax,...
                      gpStr.XMin, gpStr.DistalXMin,...
                      gpStr.XMax, gpStr.DistalXMax,...
                      gpStr.YMin, gpStr.DistalYMin,...
                      gpStr.YMax, gpStr.DistalYMax...
                      );
                 
                      ipClient.Log(strLog);

              end
       
            glPopMatrix();
            Screen('EndOpenGL', obj.viewportPtr);
            Screen('Flip', obj.viewportPtr);          
            
        end


        
        function obj = set.perspectiveAngle(obj, PerspectiveAngle)
            
            if isnumeric(PerspectiveAngle) && (PerspectiveAngle >= 0) && (PerspectiveAngle <= 180)
                
                obj.perspectiveAngle = PerspectiveAngle;
                
            else
                
                error('Perspective angle must be >=0 and <= 180');
                
            end
            
        end

        function obj = renderPerCue(obj, perCue, perCueX, perCueY, perScale, perRot, texID)

            glTranslatef(perCueX, 0, perCueY);
            
            glRotatef(perRot, 0, 1, 0);
            
            glBindTexture(obj.GL.TEXTURE_2D, texID);
            
            % Binding of normal textures using shaders
            %{
            if normID ~= -1
                
                normal = 1;
                glActiveTexture(obj.GL.TEXTURE1);
                glBindTexture(obj.GL.TEXTURE_2D, normID);
                glTexEnvfv(obj.GL.TEXTURE_ENV,obj.GL.TEXTURE_ENV_MODE,obj.GL.MODULATE);
                glActiveTexture(obj.GL.TEXTURE0);
                
            end
            %}
            
             for i = 1:numel(perCue.faces(1,:))
             
                 if numel(perCue.faces(:, 1)) == 3
                     glBegin(obj.GL.TRIANGLES);
                 else
                     glBegin(obj.GL.QUADS);
                 end
             
                 for j = 1:numel(perCue.faces(:, 1))
             
                     vertexIndex = perCue.faces(j, i) + 1;
                     texID = sum(perCue.faces(:, i)) + 3;
                     texMapping = 0;

                    if vertexIndex > 0 && vertexIndex <= numel(perCue.vertices(1,:))
                        glNormal3fv(perCue.normals(:, vertexIndex));

                        if ~isempty(perCue.texcoords)

                            for k = 1:numel(perCue.vertexTexcoordMap{1, vertexIndex})

                                if texID == perCue.vertexTexcoordMap{1,vertexIndex}(k).texnum
                                    texMapping = perCue.vertexTexcoordMap{1, vertexIndex}(k).texVals;
                                end
                            end
                           glTexCoord2fv(texMapping);
                        end 
                        glVertex3fv(perCue.vertices(:, vertexIndex) * perScale);
                    else
                        fprintf('Invalid vertex index: %d\n', vertexIndex);
                    end
                 end
                 glEnd();
             end
             
             % if normal
                 
%                 glDisable(obj.GL.TEXTURE1);
                 
             % end

        end

        function obj = drawBoundingBox(obj, boundingBox)
            % Draw the wireframe
                glBegin(obj.GL.LINES);

                % Bottom
                glVertex3fv(boundingBox(:, 1));
                glVertex3fv(boundingBox(:, 2));
            
                glVertex3fv(boundingBox(:, 2));
                glVertex3fv(boundingBox(:, 4));
            
                glVertex3fv(boundingBox(:, 4));
                glVertex3fv(boundingBox(:, 3));
            
                glVertex3fv(boundingBox(:, 3));
                glVertex3fv(boundingBox(:, 1));
            
                % Top
                glVertex3fv(boundingBox(:, 5));
                glVertex3fv(boundingBox(:, 6));
            
                glVertex3fv(boundingBox(:, 6));
                glVertex3fv(boundingBox(:, 8));
            
                glVertex3fv(boundingBox(:, 8));
                glVertex3fv(boundingBox(:, 7));
            
                glVertex3fv(boundingBox(:, 7));
                glVertex3fv(boundingBox(:, 5));
            
                % Vertical edges
                glVertex3fv(boundingBox(:, 1));
                glVertex3fv(boundingBox(:, 5));
            
                glVertex3fv(boundingBox(:, 2));
                glVertex3fv(boundingBox(:, 6));
            
                glVertex3fv(boundingBox(:, 3));
                glVertex3fv(boundingBox(:, 7));
            
                glVertex3fv(boundingBox(:, 4));
                glVertex3fv(boundingBox(:, 8));
                glEnd();
        end
        
    end
    
    methods (Static)
        
        function CaliClose()
            
            Screen('CloseAll');
            
        end
        
        function Close()
            
            ListenChar(0);
            ShowCursor;
            Screen('CloseAll');
            error('User aborted');
            
        end
        
    end
    
end
