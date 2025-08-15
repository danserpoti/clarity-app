@echo off
echo 🚀 Clarity Backend API - Quick Deploy
echo.

echo Step 1: Moving to backend-api directory...
cd /d %~dp0

echo Step 2: Checking Vercel CLI...
vercel --version
if errorlevel 1 (
    echo Installing Vercel CLI...
    npm install -g vercel
)

echo.
echo Step 3: Starting deployment...
echo Please follow the prompts:
echo - Set up and deploy "backend-api"? Y
echo - Which scope? [Select your account]
echo - Link to existing project? N
echo - Project name? clarity-backend-api
echo - Directory? ./
echo.

pause

vercel

echo.
echo ✅ Initial deployment complete!
echo.
echo 📝 Next steps:
echo 1. Go to the provided URL
echo 2. Add environment variables in Settings:
echo    - OPENAI_API_KEY = your-key-here
echo    - NODE_ENV = production
echo 3. Create KV database in Storage tab
echo 4. Run: vercel --prod
echo.

pause