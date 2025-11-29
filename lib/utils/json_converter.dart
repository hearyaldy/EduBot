/// Converts the lesson-based JSON format to question bank format
///
/// Usage: Pass your lesson JSON as input, and it will return properly formatted questions
library;

String convertLessonToQuestionBankFormat(String lessonJsonString) {
  // This is a manual conversion - you would need to parse this with dart:convert
  // in a real implementation, but here's the general structure

  // 1. Parse the lesson JSON
  // 2. Extract each section and its questions
  // 3. Convert each question to proper question bank format
  // 4. Return in the question bank format

  return '''{
  "metadata": {
    "version": "1.0",
    "exported_from": "Lesson Format Conversion",
    "exported_at": "2023-12-01T10:30:00.000Z",
    "description": "Converted from lesson format to question bank format",
    "total_questions": 40
  },
  "questions": [
    {
      "id": "lesson_year1_math_q1",
      "question_text": "How many apples are there?",
      "question_type": 2,
      "subject": "Mathematics",
      "topic": "Whole Numbers",
      "subtopic": "Counting",
      "grade_level": 1,
      "difficulty": 1,
      "answer_key": "7",
      "explanation": "The image shows a group of seven apples. Counting them one by one gives the total number.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["KSSR Year 1 Mathematics 1.0"],
        "tags": ["counting", "visual", "basic"],
        "estimated_time_minutes": 2,
        "cognitive_level": 1,
        "additional_data": {
          "original_section": "1.0 Whole Numbers Up to 100",
          "original_question_number": 1
        }
      }
    },
    {
      "id": "lesson_year1_math_q2",
      "question_text": "Which number is bigger, 15 or 23?",
      "question_type": 2,
      "subject": "Mathematics", 
      "topic": "Whole Numbers",
      "subtopic": "Number Comparison",
      "grade_level": 1,
      "difficulty": 1,
      "answer_key": "23",
      "explanation": "When comparing two numbers, the number with the higher value is bigger. 23 is greater than 15.",
      "choices": ["15", "23"],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["KSSR Year 1 Mathematics 1.0"],
        "tags": ["comparison", "number_sense"],
        "estimated_time_minutes": 2,
        "cognitive_level": 1,
        "additional_data": {
          "original_section": "1.0 Whole Numbers Up to 100", 
          "original_question_number": 2
        }
      }
    }
    // ... continue for all questions in your lesson
  ]
}''';
}

/// For your specific science questions, here's the correct format:
String getScienceQuestionsTemplate() {
  return '''{
  "metadata": {
    "version": "1.0", 
    "exported_from": "Manual Import",
    "exported_at": "2023-12-01T10:30:00.000Z",
    "description": "Science questions for waste management topic",
    "total_questions": 2
  },
  "questions": [
    {
      "id": "science_waste_001",
      "question_text": "Is a banana peel biodegradable?",
      "question_type": 2,
      "subject": "Science",
      "topic": "Waste Management", 
      "subtopic": "Biodegradable Materials",
      "grade_level": 3,
      "difficulty": 1,
      "answer_key": "Yes",
      "explanation": "Banana peels are organic and can be broken down naturally by microorganisms.",
      "choices": ["Yes", "No"],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["Science Curriculum"],
        "tags": ["environment", "waste", "biodegradable"],
        "estimated_time_minutes": 2,
        "cognitive_level": 1,
        "additional_data": {}
      }
    },
    {
      "id": "science_waste_002", 
      "question_text": "What does 'non-biodegradable' mean?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Waste Management",
      "subtopic": "Non-Biodegradable Materials", 
      "grade_level": 3,
      "difficulty": 1,
      "answer_key": "Cannot be broken down naturally by microorganisms.",
      "explanation": "Non-biodegradable waste, like plastic, persists in the environment for hundreds of years.",
      "choices": [],
      "target_language": "English", 
      "metadata": {
        "curriculum_standards": ["Science Curriculum"],
        "tags": ["environment", "waste", "non-biodegradable"],
        "estimated_time_minutes": 2,
        "cognitive_level": 1,
        "additional_data": {}
      }
    }
  ]
}''';
}
