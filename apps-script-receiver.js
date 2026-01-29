// Google Apps Script - Paste this into your Google Sheet's Apps Script editor
// Go to Extensions > Apps Script, paste this, then Deploy > New deployment > Web app

const SHEET_NAME = 'Profiles'; // Change if needed

function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);

    // Create sheet if it doesn't exist
    if (!sheet) {
      const newSheet = SpreadsheetApp.getActiveSpreadsheet().insertSheet(SHEET_NAME);
      // Add headers
      newSheet.getRange(1, 1, 1, 13).setValues([[
        'First Name', 'Last Name', 'Full Name', 'LinkedIn', 'Headline',
        'Title', 'Company', 'Location', 'School', 'Degree',
        'Skills', 'Experience', 'Added At'
      ]]);
    }

    const targetSheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);

    // Append row
    targetSheet.appendRow([
      data.first_name || '',
      data.last_name || '',
      data.full_name || '',
      data.linkedin_link || '',
      data.headline || '',
      data.title || '',
      data.company || '',
      data.location || '',
      data.school || '',
      data.degree || '',
      data.skills || '',
      data.experience || '',
      data.parsed_at || new Date().toISOString()
    ]);

    return ContentService.createTextOutput(JSON.stringify({ success: true }))
      .setMimeType(ContentService.MimeType.JSON);

  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({ success: false, error: error.message }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

function doGet(e) {
  return ContentService.createTextOutput('LinkedIn PDF Uploader API is running')
    .setMimeType(ContentService.MimeType.TEXT);
}

// Test function
function testAppend() {
  const testData = {
    first_name: 'Test',
    last_name: 'User',
    full_name: 'Test User',
    linkedin_link: 'https://linkedin.com/in/testuser',
    headline: 'Software Engineer at Google',
    title: 'Software Engineer',
    company: 'Google',
    location: 'San Francisco, CA',
    school: 'Stanford University',
    degree: 'BS Computer Science',
    skills: 'JavaScript, Python, React',
    experience: 'Software Engineer @ Google',
    parsed_at: new Date().toISOString()
  };

  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME) ||
                SpreadsheetApp.getActiveSpreadsheet().insertSheet(SHEET_NAME);

  if (sheet.getLastRow() === 0) {
    sheet.getRange(1, 1, 1, 13).setValues([[
      'First Name', 'Last Name', 'Full Name', 'LinkedIn', 'Headline',
      'Title', 'Company', 'Location', 'School', 'Degree',
      'Skills', 'Experience', 'Added At'
    ]]);
  }

  sheet.appendRow([
    testData.first_name,
    testData.last_name,
    testData.full_name,
    testData.linkedin_link,
    testData.headline,
    testData.title,
    testData.company,
    testData.location,
    testData.school,
    testData.degree,
    testData.skills,
    testData.experience,
    testData.parsed_at
  ]);

  Logger.log('Test row added!');
}
