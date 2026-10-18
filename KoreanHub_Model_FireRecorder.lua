-- Passive, scoped recorder: forwards all calls unchanged; never fires a remote.
local env=type(getgenv)=='function' and getgenv() or _G
local Players=game:GetService('Players')
local player=Players.LocalPlayer
if env.KoreanHubFireRecordSession then env.KoreanHubFireRecordSession.active=false end
local state={active=true,count=0,text='총을 장착하고 평소처럼 직접 한 발 쏘세요.\n자동 공격·Triggerbot은 먼저 꺼주세요.'}
env.KoreanHubFireRecordSession=state
local parent=player:WaitForChild('PlayerGui')
local oldGui=parent:FindFirstChild('KoreanHubFireRecorder')
if oldGui then oldGui:Destroy() end
local gui=Instance.new('ScreenGui')
gui.Name='KoreanHubFireRecorder';gui.ResetOnSpawn=false;gui.DisplayOrder=10001;gui.Parent=parent
local frame=Instance.new('Frame')
frame.Size=UDim2.fromScale(.84,.66);frame.Position=UDim2.fromScale(.08,.17)
frame.BackgroundColor3=Color3.fromRGB(25,28,32);frame.Parent=gui
local title=Instance.new('TextLabel')
title.Size=UDim2.new(1,0,0,32);title.BackgroundTransparency=1;title.TextColor3=Color3.new(1,1,1)
title.Text='Model 발사 인수 기록 · 버튼으로 숨긴 뒤 직접 발사';title.TextSize=15;title.Parent=frame
local scroll=Instance.new('ScrollingFrame')
scroll.Position=UDim2.new(0,8,0,80);scroll.Size=UDim2.new(1,-16,1,-88)
scroll.BackgroundTransparency=1;scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroll.CanvasSize=UDim2.new();scroll.Parent=frame
local label=Instance.new('TextLabel')
label.Size=UDim2.new(1,-12,0,0);label.AutomaticSize=Enum.AutomaticSize.Y;label.TextWrapped=true
label.BackgroundTransparency=1;label.TextColor3=Color3.new(1,1,1);label.Font=Enum.Font.Code;label.TextSize=14
label.TextXAlignment=Enum.TextXAlignment.Left;label.TextYAlignment=Enum.TextYAlignment.Top;label.Parent=scroll
local function show(text) state.text=text;label.Text=text end
local function button(text,x,fn)
 local b=Instance.new('TextButton');b.Size=UDim2.new(.24,0,0,36);b.Position=UDim2.new(x,0,0,36)
 b.Text=text;b.TextSize=14;b.Parent=frame;b.Activated:Connect(fn)
end
local reopen=Instance.new('TextButton')
reopen.Size=UDim2.fromOffset(150,40);reopen.Position=UDim2.new(.02,0,.7,0)
reopen.Text='발사 기록 보기';reopen.Visible=false;reopen.Parent=gui
reopen.Activated:Connect(function() frame.Visible=true;reopen.Visible=false end)
button('숨기고 발사',.01,function() frame.Visible=false;reopen.Visible=true end)
button('복사',.26,function()
 local copy=setclipboard or toclipboard
 if type(copy)=='function' then pcall(copy,state.text) else title.Text='복사 미지원 · 기록 화면을 찍어 보내세요' end
end)
button('저장',.51,function()
 if type(writefile)=='function' then
  local ok=pcall(writefile,'KoreanHub_FireRecord.txt',state.text)
  title.Text=ok and 'KoreanHub_FireRecord.txt 저장됨' or '저장 실패'
 end
end)
button('기록 중지',.76,function() state.active=false;title.Text='기록 중지됨 · 기존 발사에는 영향 없음' end)
show(state.text)
local function encode(value,depth,seen)
 local kind=typeof(value)
 if kind=='Instance' then return 'Instance('..value.ClassName..') '..value:GetFullName() end
 if kind=='table' then
  if depth>=3 or seen[value] then return '<table limit>' end
  seen[value]=true
  local out={};local n=0
  for k,v in pairs(value) do
   n=n+1;if n>24 then out[#out+1]='...';break end
   out[#out+1]='['..tostring(k):sub(1,80)..']='..encode(v,depth+1,seen)
  end
  return '{'..table.concat(out,', ')..'}'
 end
 return kind..': '..tostring(value):sub(1,250)
end
state.capture=function(remote,args)
 if not state.active or state.count>=3 then return end
 if not remote:IsA('RemoteEvent') or remote.Name~='Activate' then return end
 local model=remote.Parent
 if not model or not model:IsA('Model') or model.Parent~=player.Character or not model:FindFirstChild('ToolSlot') then return end
 state.count=state.count+1
 local lines={'KoreanHub model fire record 1','PlaceId='..game.PlaceId,'Weapon='..model.Name,'Remote='..remote:GetFullName(),'Capture='..state.count,'Arguments='..args.n}
 local camera=workspace.CurrentCamera
 if camera then
  lines[#lines+1]='Camera='..tostring(camera.CFrame)
  lines[#lines+1]='Viewport='..tostring(camera.ViewportSize)
 end
 local handle=model:FindFirstChild('Handle')
 if handle and handle:IsA('BasePart') then lines[#lines+1]='Handle='..tostring(handle.CFrame) end
 for i=1,args.n do lines[#lines+1]='arg['..i..']='..encode(args[i],0,{}) end
 local text=table.concat(lines,'\n')
 task.defer(function()
  if env.KoreanHubFireRecordSession~=state then return end
  show(text);print(text);reopen.Text='기록 '..state.count..'개 · 보기'
 end)
end
if not env.KoreanHubFireRecordHookInstalled then
 if type(hookmetamethod)~='function' or type(getnamecallmethod)~='function' then
  state.active=false;show('이 실행기에서 수동 발사 기록 API를 사용할 수 없습니다.\nhookmetamethod / getnamecallmethod 미지원');return
 end
 local original
 local function intercept(self,...)
  local current=env.KoreanHubFireRecordSession
  if current and current.active and getnamecallmethod()=='FireServer' then
   local args=table.pack(...)
   pcall(current.capture,self,args)
  end
  return original(self,...)
 end
 local callback=type(newcclosure)=='function' and newcclosure(intercept) or intercept
 local ok,result=pcall(function() return hookmetamethod(game,'__namecall',callback) end)
 if not ok then state.active=false;show('기록 연결 실패: '..tostring(result));return end
 original=result
 env.KoreanHubFireRecordHookInstalled=true
end
