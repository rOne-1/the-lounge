const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const outputDir = 'C:/Users/myhea/.gemini/antigravity/brain/13c8995a-1a40-4f65-8cd0-c6bd4393c126/step4_verification';
if (!fs.existsSync(outputDir)) {
  fs.mkdirSync(outputDir, { recursive: true });
}

(async () => {
  console.log('Launching browser...');
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
  });
  const page = await context.newPage();

  console.log('Navigating to http://localhost:3000...');
  await page.goto('http://localhost:3000', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000); // Wait for Flutter engine & mock data futures to resolve

  // 1. Initial Home Screen Screenshot
  console.log('1. Initial Home Screen');
  await page.screenshot({ path: path.join(outputDir, '01_home_screening_room.png') });

  // 2. Click Ambiance toggle (top right icon)
  console.log('2. Toggle Ambiance (Reading Room)');
  await page.mouse.click(350, 35);
  await page.waitForTimeout(700); // 550ms animation + margin
  await page.screenshot({ path: path.join(outputDir, '02_home_reading_room.png') });

  // Toggle back to Screening Room
  await page.mouse.click(350, 35);
  await page.waitForTimeout(700);

  // 3. Movies / TV Segmented Toggle
  console.log('3. Toggle Movies / TV');
  await page.mouse.click(110, 35); // Click TV
  await page.waitForTimeout(600);
  await page.screenshot({ path: path.join(outputDir, '03_media_toggle_tv.png') });
  await page.mouse.click(50, 35); // Click back to Movies
  await page.waitForTimeout(600);

  // 4. Navigation Bar Tabs
  console.log('4. Navigate to Discover');
  await page.mouse.click(117, 780);
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(outputDir, '04_discover_tab.png') });

  // Legend button on Discover Screen (top right of screen body)
  console.log('4b. Open Discover Legend Bottom Sheet');
  await page.mouse.click(350, 90);
  await page.waitForTimeout(700);
  await page.screenshot({ path: path.join(outputDir, '05_discover_legend_sheet.png') });
  
  // Dismiss sheet (click scrim ~ (200, 200))
  await page.mouse.click(200, 200);
  await page.waitForTimeout(500);

  // Discover card action buttons
  console.log('4c. Discover Card Action (Fly-off animation)');
  await page.mouse.click(250, 580);
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(outputDir, '06_discover_card_flyoff.png') });
  await page.waitForTimeout(500);

  console.log('4d. Navigate to Search');
  await page.mouse.click(195, 780);
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(outputDir, '07_search_tab.png') });

  console.log('4e. Navigate to Your Space');
  await page.mouse.click(273, 780);
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(outputDir, '08_your_space_tab.png') });

  console.log('4f. Navigate to Calendar');
  await page.mouse.click(351, 780);
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(outputDir, '09_calendar_tab.png') });

  // Return to Home tab
  console.log('4g. Return to Home');
  await page.mouse.click(39, 780);
  await page.waitForTimeout(800);

  // 5. ContainerTransform to DetailScreen
  // Click on a movie poster item in Trending Now (x: 70, y: 460)
  console.log('5. Click Poster to open DetailScreen');
  await page.mouse.click(70, 460);
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(outputDir, '10_detail_screen.png') });

  // Close DetailScreen (Click back arrow at top left ~ x: 30, y: 35)
  console.log('5b. Close DetailScreen');
  await page.mouse.click(30, 35);
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(outputDir, '11_returned_home.png') });

  await browser.close();
  console.log('Verification completed successfully! Screenshots saved to ' + outputDir);
})();
