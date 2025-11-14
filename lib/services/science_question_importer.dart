import 'dart:convert';
import '../services/question_import_service.dart';
import '../models/question.dart';

class ScienceQuestionImporter {
  final QuestionImportService _importService = QuestionImportService();

  /// Import the Year 6 Science questions directly
  Future<Map<String, dynamic>> importYear6ScienceQuestions() async {
    final jsonString = '''{
  "metadata": {
    "version": "1.0",
    "exported_from": "Manual Import",
    "exported_at": "2025-11-14T08:00:00.000Z",
    "description": "Year 6 Science: Comprehensive Practice (Based on KSSR Curriculum)",
    "total_questions": 55
  },
  "questions": [
    {
      "id": "science_reproduction_001",
      "question_text": "What is the function of the ovary in the female reproductive system?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Human Reproduction",
      "subtopic": "Female Reproductive Organs",
      "grade_level": 6,
      "difficulty": 1,
      "answer_key": "Produces eggs | Produces hormones",
      "explanation": "The ovaries have two main functions: they produce egg cells (ova) and secrete the female sex hormones estrogen and progesterone.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["reproduction", "human", "ovary", "female"],
        "estimated_time_minutes": 2,
        "cognitive_level": 2,
        "additional_data": {}
      }
    },
    {
      "id": "science_reproduction_002",
      "question_text": "Describe what happens during fertilization in humans.",
      "question_type": 3,
      "subject": "Science",
      "topic": "Human Reproduction",
      "subtopic": "Fertilization",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Sperm fuses with egg to form zygote",
      "explanation": "Fertilization occurs when a sperm cell from the male unites with an egg cell (ovum) from the female in the fallopian tube. This fusion forms a single cell called a zygote, which is the first stage of a new individual.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["fertilization", "zygote", "sperm", "egg"],
        "estimated_time_minutes": 3,
        "cognitive_level": 3,
        "additional_data": {}
      }
    },
    {
      "id": "science_reproduction_003",
      "question_text": "Why is reproduction important for the survival of the human species?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Human Reproduction",
      "subtopic": "Importance of Reproduction",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "To continue the species | To replace dead individuals",
      "explanation": "Reproduction is essential because it allows humans to produce offspring. This ensures that the human species continues to exist over time by replacing individuals who die, thus maintaining the population.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["reproduction", "species", "survival"],
        "estimated_time_minutes": 3,
        "cognitive_level": 4,
        "additional_data": {}
      }
    },
    {
      "id": "science_reproduction_004",
      "question_text": "Name one part of the male reproductive system and state its function.",
      "question_type": 3,
      "subject": "Science",
      "topic": "Human Reproduction",
      "subtopic": "Male Reproductive Organs",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "Testis - produces sperm and testosterone | Penis - delivers sperm into the female body",
      "explanation": "The testes are responsible for producing sperm cells and the hormone testosterone. The penis is the external organ used to deliver sperm into the female's vagina during sexual intercourse.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["male", "reproduction", "testis", "penis"],
        "estimated_time_minutes": 4,
        "cognitive_level": 5,
        "additional_data": {}
      }
    },
    {
      "id": "science_reproduction_005",
      "question_text": "Where does the embryo develop and grow after fertilization?",
      "question_type": 2,
      "subject": "Science",
      "topic": "Human Reproduction",
      "subtopic": "Embryonic Development",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "Uterus",
      "explanation": "After fertilization in the fallopian tube, the zygote travels down to the uterus. It implants itself into the thickened lining of the uterus wall, where it develops and grows into an embryo and then a fetus until birth.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["embryo", "uterus", "development", "pregnancy"],
        "estimated_time_minutes": 4,
        "cognitive_level": 5,
        "additional_data": {}
      }
    },
    {
      "id": "science_nervous_001",
      "question_text": "Name the two main types of the human nervous system.",
      "question_type": 2,
      "subject": "Science",
      "topic": "Nervous System",
      "subtopic": "Types of Nervous System",
      "grade_level": 6,
      "difficulty": 1,
      "answer_key": "Central nervous system and peripheral nervous system",
      "explanation": "The human nervous system is divided into the Central Nervous System (CNS), which includes the brain and spinal cord, and the Peripheral Nervous System (PNS), which consists of all the nerves that branch out from the CNS to the rest of the body.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["nervous", "system", "CNS", "PNS"],
        "estimated_time_minutes": 2,
        "cognitive_level": 1,
        "additional_data": {}
      }
    },
    {
      "id": "science_nervous_002",
      "question_text": "What are the two main parts of the central nervous system?",
      "question_type": 2,
      "subject": "Science",
      "topic": "Nervous System",
      "subtopic": "Central Nervous System",
      "grade_level": 6,
      "difficulty": 1,
      "answer_key": "Brain and spinal cord",
      "explanation": "The central nervous system (CNS) is composed of the brain, which is located in the skull, and the spinal cord, which runs down the back inside the spine. These organs process information and coordinate the body's activities.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["brain", "spinal", "cord", "CNS"],
        "estimated_time_minutes": 2,
        "cognitive_level": 1,
        "additional_data": {}
      }
    },
    {
      "id": "science_nervous_003",
      "question_text": "What would happen if your peripheral nervous system stopped working?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Nervous System",
      "subtopic": "Peripheral Nervous System",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Can't feel or move parts of body",
      "explanation": "If the peripheral nervous system failed, signals could not be sent between the central nervous system (brain and spinal cord) and the limbs and organs. This would result in a loss of sensation (you couldn't feel pain, heat, etc.) and motor control (you couldn't move your muscles voluntarily).",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["peripheral", "nerves", "function", "failure"],
        "estimated_time_minutes": 3,
        "cognitive_level": 4,
        "additional_data": {}
      }
    },
    {
      "id": "science_nervous_004",
      "question_text": "How can you protect your nervous system while riding a motorcycle?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Nervous System",
      "subtopic": "Protection of Nervous System",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Wear a helmet",
      "explanation": "Wearing a helmet is a crucial way to protect the nervous system, specifically the brain, when riding a motorcycle. In the event of a fall or accident, the helmet absorbs the impact and prevents serious head injuries that could damage the brain.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["protection", "helmet", "motorcycle", "brain"],
        "estimated_time_minutes": 3,
        "cognitive_level": 3,
        "additional_data": {}
      }
    },
    {
      "id": "science_nervous_005",
      "question_text": "What is the primary function of the peripheral nervous system?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Nervous System",
      "subtopic": "Function of PNS",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "Transmits signals between CNS and body",
      "explanation": "The primary function of the peripheral nervous system is to act as a communication network. It carries sensory information from the body's senses to the central nervous system (CNS) and transmits motor commands from the CNS to the muscles and glands.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["PNS", "function", "signals", "communication"],
        "estimated_time_minutes": 4,
        "cognitive_level": 5,
        "additional_data": {}
      }
    },
    {
      "id": "science_microbes_001",
      "question_text": "Name three different types of microorganisms.",
      "question_type": 2,
      "subject": "Science",
      "topic": "Microorganisms",
      "subtopic": "Types of Microorganisms",
      "grade_level": 6,
      "difficulty": 1,
      "answer_key": "Bacteria, virus, fungus | Bacteria, protozoa, algae",
      "explanation": "The five main types of microorganisms are bacteria, viruses, fungi, protozoa, and algae. Any three of these are correct answers.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["microorganism", "types", "bacteria", "fungi"],
        "estimated_time_minutes": 2,
        "cognitive_level": 1,
        "additional_data": {}
      }
    },
    {
      "id": "science_microbes_002",
      "question_text": "List three factors that affect the growth of microorganisms.",
      "question_type": 2,
      "subject": "Science",
      "topic": "Microorganisms",
      "subtopic": "Growth Factors",
      "grade_level": 6,
      "difficulty": 1,
      "answer_key": "Nutrients, moisture, temperature | Temperature, pH, air",
      "explanation": "The growth of microorganisms is influenced by several environmental factors, including nutrients (food source), moisture (water), temperature, pH (acidity/alkalinity), and the presence of air (oxygen).",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["growth", "factors", "temperature", "moisture"],
        "estimated_time_minutes": 2,
        "cognitive_level": 1,
        "additional_data": {}
      }
    },
    {
      "id": "science_microbes_003",
      "question_text": "Give one example of how microorganisms are beneficial in our daily lives.",
      "question_type": 3,
      "subject": "Science",
      "topic": "Microorganisms",
      "subtopic": "Beneficial Microorganisms",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Making yogurt | Decomposing waste",
      "explanation": "Microorganisms have many beneficial uses. For example, specific bacteria are used in the production of foods like yogurt, cheese, and bread. Other microorganisms, such as those in compost, help decompose organic waste, turning it into useful fertilizer.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["benefits", "yogurt", "decomposition"],
        "estimated_time_minutes": 3,
        "cognitive_level": 3,
        "additional_data": {}
      }
    },
    {
      "id": "science_microbes_004",
      "question_text": "How do microorganisms cause food to spoil?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Microorganisms",
      "subtopic": "Food Spoilage",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "They grow and reproduce on the food",
      "explanation": "Microorganisms cause food spoilage by feeding on the nutrients in the food. As they grow and multiply, they break down the food's components, leading to changes in smell, taste, texture, and appearance, making the food unsafe or unpleasant to eat.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["spoiling", "food", "microbe", "reproduce"],
        "estimated_time_minutes": 3,
        "cognitive_level": 4,
        "additional_data": {}
      }
    },
    {
      "id": "science_microbes_005",
      "question_text": "What is the meaning of the term 'microorganism'?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Microorganisms",
      "subtopic": "Definition",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "A living thing too small to see with naked eye",
      "explanation": "A microorganism, or microbe, is a microscopic organism that is too small to be seen clearly with the naked eye. They are typically studied using a microscope.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["definition", "microorganism", "microscopic"],
        "estimated_time_minutes": 4,
        "cognitive_level": 6,
        "additional_data": {}
      }
    },
    {
      "id": "science_interactions_001",
      "question_text": "Define 'predation' and give an example.",
      "question_type": 3,
      "subject": "Science",
      "topic": "Interactions Among Animals",
      "subtopic": "Predation",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "One animal hunts another for food (e.g., lion and zebra)",
      "explanation": "Predation is a biological interaction where one organism, the predator, kills and eats another organism, its prey. A classic example is a lion (predator) hunting and killing a zebra (prey) for food.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["predation", "predator", "prey", "interaction"],
        "estimated_time_minutes": 3,
        "cognitive_level": 4,
        "additional_data": {}
      }
    },
    {
      "id": "science_interactions_002",
      "question_text": "What are two resources that animals might compete for?",
      "question_type": 2,
      "subject": "Science",
      "topic": "Interactions Among Animals",
      "subtopic": "Competition",
      "grade_level": 6,
      "difficulty": 1,
      "answer_key": "Food and water | Territory and mates",
      "explanation": "Animals often compete for essential resources needed for survival and reproduction. Common examples include food, water, shelter, territory, and potential mates.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["competition", "resources", "food", "water"],
        "estimated_time_minutes": 2,
        "cognitive_level": 1,
        "additional_data": {}
      }
    },
    {
      "id": "science_interactions_003",
      "question_text": "Explain the difference between mutualism and parasitism.",
      "question_type": 3,
      "subject": "Science",
      "topic": "Interactions Among Animals",
      "subtopic": "Symbiosis",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Mutualism: both benefit. Parasitism: one benefits, one harmed",
      "explanation": "In mutualism, both organisms involved benefit from the relationship (e.g., bees and flowers). In parasitism, one organism (the parasite) benefits at the expense of the other (the host), which is harmed (e.g., a tick feeding on a dog).",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["mutualism", "parasitism", "symbiosis", "difference"],
        "estimated_time_minutes": 3,
        "cognitive_level": 5,
        "additional_data": {}
      }
    },
    {
      "id": "science_interactions_004",
      "question_text": "Give an example of commensalism in nature.",
      "question_type": 3,
      "subject": "Science",
      "topic": "Interactions Among Animals",
      "subtopic": "Commensalism",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "Remora fish and shark | Birds nesting in trees",
      "explanation": "Commensalism is a relationship where one organism benefits and the other is neither helped nor harmed. An example is the remora fish, which attaches itself to a shark to get transportation and scraps of food, while the shark is unaffected.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["commensalism", "example", "remora", "shark"],
        "estimated_time_minutes": 4,
        "cognitive_level": 6,
        "additional_data": {}
      }
    },
    {
      "id": "science_interactions_005",
      "question_text": "Why are interactions between living things important for an ecosystem?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Interactions Among Animals",
      "subtopic": "Ecosystem Balance",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "Maintains balance | Controls population",
      "explanation": "Interactions such as predation, competition, and symbiosis are crucial for maintaining the balance within an ecosystem. They help control populations of different species, ensure the flow of energy through food chains, and contribute to the overall health and stability of the environment.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["ecosystem", "balance", "interactions", "importance"],
        "estimated_time_minutes": 4,
        "cognitive_level": 6,
        "additional_data": {}
      }
    },
    {
      "id": "science_conservation_001",
      "question_text": "What is the difference between conservation and preservation?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Conservation and Preservation",
      "subtopic": "Definitions",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Conservation: use wisely. Preservation: protect from use",
      "explanation": "Conservation involves the sustainable use and management of natural resources so they are not depleted. Preservation means protecting something in its natural state, often by preventing any human use or interference.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["conservation", "preservation", "difference", "environment"],
        "estimated_time_minutes": 3,
        "cognitive_level": 4,
        "additional_data": {}
      }
    },
    {
      "id": "science_conservation_002",
      "question_text": "Name two endangered animals found in Malaysia.",
      "question_type": 2,
      "subject": "Science",
      "topic": "Conservation and Preservation",
      "subtopic": "Endangered Species",
      "grade_level": 6,
      "difficulty": 1,
      "answer_key": "Malayan tiger and orangutan | Asian elephant and rhinoceros",
      "explanation": "Some well-known endangered animals in Malaysia include the Malayan Tiger, the Bornean Orangutan, the Asian Elephant, and the Sumatran Rhinoceros.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["endangered", "animals", "Malaysia", "tiger"],
        "estimated_time_minutes": 2,
        "cognitive_level": 2,
        "additional_data": {}
      }
    },
    {
      "id": "science_conservation_003",
      "question_text": "What is one major cause of animal extinction?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Conservation and Preservation",
      "subtopic": "Causes of Extinction",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Habitat loss",
      "explanation": "One of the biggest causes of animal extinction is habitat loss, primarily due to deforestation, urban development, and agriculture, which destroys the natural environments where animals live and find food.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["extinction", "habitat", "loss", "deforestation"],
        "estimated_time_minutes": 3,
        "cognitive_level": 3,
        "additional_data": {}
      }
    },
    {
      "id": "science_conservation_004",
      "question_text": "Suggest one way we can help conserve wildlife.",
      "question_type": 3,
      "subject": "Science",
      "topic": "Conservation and Preservation",
      "subtopic": "Wildlife Conservation",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Stop illegal hunting | Protect forests",
      "explanation": "There are many ways to help conserve wildlife, such as supporting anti-poaching efforts, protecting natural habitats from destruction, reducing pollution, and promoting sustainable practices.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["conserve", "wildlife", "protect", "hunting"],
        "estimated_time_minutes": 3,
        "cognitive_level": 4,
        "additional_data": {}
      }
    },
    {
      "id": "science_conservation_005",
      "question_text": "Why should we care about preserving endangered species?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Conservation and Preservation",
      "subtopic": "Importance of Preservation",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "For ecological balance | For future generations",
      "explanation": "Preserving endangered species is vital for maintaining biodiversity and the balance of ecosystems. Each species plays a role in its environment, and losing one can have cascading effects. It also preserves the planet's natural heritage for future generations.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["preserve", "endangered", "balance", "future"],
        "estimated_time_minutes": 4,
        "cognitive_level": 6,
        "additional_data": {}
      }
    },
    {
      "id": "science_food_spoilage_001",
      "question_text": "List three signs that indicate food has gone bad.",
      "question_type": 2,
      "subject": "Science",
      "topic": "Food Spoilage",
      "subtopic": "Signs of Spoilage",
      "grade_level": 6,
      "difficulty": 1,
      "answer_key": "Bad smell, mold, change in color",
      "explanation": "Common signs of spoiled food include an unpleasant or sour odor, the presence of mold (fuzzy spots), a change in color (e.g., meat turning gray), a slimy texture, or an off taste.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["spoilage", "signs", "smell", "mold"],
        "estimated_time_minutes": 2,
        "cognitive_level": 1,
        "additional_data": {}
      }
    },
    {
      "id": "science_food_spoilage_002",
      "question_text": "What causes food to spoil?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Food Spoilage",
      "subtopic": "Cause of Spoilage",
      "grade_level": 6,
      "difficulty": 1,
      "answer_key": "Growth of microorganisms",
      "explanation": "Food spoils primarily due to the growth and activity of microorganisms such as bacteria, yeasts, and molds. These microbes break down the food, leading to undesirable changes.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["cause", "spoilage", "microbes", "decay"],
        "estimated_time_minutes": 2,
        "cognitive_level": 2,
        "additional_data": {}
      }
    },
    {
      "id": "science_food_spoilage_003",
      "question_text": "How does drying food help to preserve it?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Food Spoilage",
      "subtopic": "Preservation Methods",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Removes water needed by microorganisms",
      "explanation": "Drying removes moisture from food. Since microorganisms need water to grow and reproduce, removing this essential factor prevents their growth and thus preserves the food.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["drying", "preservation", "moisture", "microbe"],
        "estimated_time_minutes": 3,
        "cognitive_level": 4,
        "additional_data": {}
      }
    },
    {
      "id": "science_food_spoilage_004",
      "question_text": "Why is pasteurization effective in preserving milk?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Food Spoilage",
      "subtopic": "Pasteurization",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Kills harmful microorganisms",
      "explanation": "Pasteurization involves heating milk to a high temperature for a short time. This process kills most of the harmful bacteria and other microorganisms present in the milk without significantly changing its taste, thereby extending its shelf life.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["pasteurization", "milk", "kills", "bacteria"],
        "estimated_time_minutes": 3,
        "cognitive_level": 4,
        "additional_data": {}
      }
    },
    {
      "id": "science_food_spoilage_005",
      "question_text": "Name two methods of food preservation that involve low temperatures.",
      "question_type": 2,
      "subject": "Science",
      "topic": "Food Spoilage",
      "subtopic": "Temperature-based Preservation",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "Refrigeration and freezing",
      "explanation": "Refrigeration (cooling) and freezing are common preservation methods that slow down or stop the growth of microorganisms by lowering the temperature of the food.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["refrigeration", "freezing", "cold", "preservation"],
        "estimated_time_minutes": 4,
        "cognitive_level": 5,
        "additional_data": {}
      }
    },
    {
      "id": "science_waste_001",
      "question_text": "What is the difference between biodegradable and non-biodegradable waste?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Waste Management",
      "subtopic": "Biodegradability",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Biodegradable: breaks down naturally. Non-biodegradable: does not.",
      "explanation": "Biodegradable waste, such as food scraps and paper, can be broken down naturally by microorganisms into simpler substances. Non-biodegradable waste, like plastic and glass, cannot be broken down by natural processes and persists in the environment for a very long time.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["biodegradable", "non-biodegradable", "waste", "difference"],
        "estimated_time_minutes": 3,
        "cognitive_level": 4,
        "additional_data": {}
      }
    },
    {
      "id": "science_waste_002",
      "question_text": "Classify the following items as biodegradable or non-biodegradable: apple core, plastic bottle, newspaper, metal can.",
      "question_type": 2,
      "subject": "Science",
      "topic": "Waste Management",
      "subtopic": "Classification",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Apple core: biodegradable. Plastic bottle: non-biodegradable. Newspaper: biodegradable. Metal can: non-biodegradable.",
      "explanation": "Organic materials like an apple core and paper (newspaper) will decompose naturally. Synthetic materials like plastic and durable metals (can) do not decompose easily and are classified as non-biodegradable.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["classify", "waste", "biodegradable", "plastic"],
        "estimated_time_minutes": 3,
        "cognitive_level": 4,
        "additional_data": {}
      }
    },
    {
      "id": "science_waste_003",
      "question_text": "What does the term '5R' stand for in waste management?",
      "question_type": 2,
      "subject": "Science",
      "topic": "Waste Management",
      "subtopic": "5R Principle",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "Refuse, Reduce, Reuse, Recycle, Repair",
      "explanation": "The 5Rs are a hierarchy of actions to minimize waste: Refuse unnecessary items, Reduce consumption, Reuse items, Recycle materials, and Repair broken items instead of discarding them.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["5R", "waste", "management", "reduce"],
        "estimated_time_minutes": 4,
        "cognitive_level": 5,
        "additional_data": {}
      }
    },
    {
      "id": "science_waste_004",
      "question_text": "Why is it important to manage waste properly?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Waste Management",
      "subtopic": "Importance",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Prevents pollution | Protects environment",
      "explanation": "Proper waste management is crucial to prevent pollution of land, water, and air. It helps protect public health, conserves natural resources, reduces greenhouse gas emissions, and maintains a clean and healthy environment.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["importance", "pollution", "environment", "health"],
        "estimated_time_minutes": 3,
        "cognitive_level": 5,
        "additional_data": {}
      }
    },
    {
      "id": "science_waste_005",
      "question_text": "Give an example of how you can reuse a common household item.",
      "question_type": 3,
      "subject": "Science",
      "topic": "Waste Management",
      "subtopic": "Reuse",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "Use a glass jar for storage",
      "explanation": "Reusing items extends their life and reduces waste. For example, an empty glass jar from jam or sauce can be cleaned and reused to store dry goods, spices, or even as a drinking glass.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["reuse", "recycling", "jar", "storage"],
        "estimated_time_minutes": 4,
        "cognitive_level": 6,
        "additional_data": {}
      }
    },
    {
      "id": "science_eclipse_001",
      "question_text": "During a solar eclipse, what is the correct order of the Sun, Moon, and Earth?",
      "question_type": 2,
      "subject": "Science",
      "topic": "Eclipses",
      "subtopic": "Solar Eclipse",
      "grade_level": 6,
      "difficulty": 1,
      "answer_key": "Sun, Moon, Earth",
      "explanation": "A solar eclipse occurs when the Moon passes directly between the Sun and the Earth, blocking the Sun's light from reaching parts of the Earth. The order is Sun -> Moon -> Earth.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["solar", "eclipse", "order", "moon"],
        "estimated_time_minutes": 2,
        "cognitive_level": 2,
        "additional_data": {}
      }
    },
    {
      "id": "science_eclipse_002",
      "question_text": "During a lunar eclipse, what is the correct order of the Sun, Earth, and Moon?",
      "question_type": 2,
      "subject": "Science",
      "topic": "Eclipses",
      "subtopic": "Lunar Eclipse",
      "grade_level": 6,
      "difficulty": 1,
      "answer_key": "Sun, Earth, Moon",
      "explanation": "A lunar eclipse happens when the Earth passes directly between the Sun and the Moon, causing the Earth's shadow to fall on the Moon. The order is Sun -> Earth -> Moon.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["lunar", "eclipse", "order", "earth"],
        "estimated_time_minutes": 2,
        "cognitive_level": 2,
        "additional_data": {}
      }
    },
    {
      "id": "science_eclipse_003",
      "question_text": "Why must you never look directly at a solar eclipse?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Eclipses",
      "subtopic": "Safety",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "It can damage your eyes",
      "explanation": "Looking directly at the Sun, even during a partial solar eclipse, can cause severe and permanent eye damage, including blindness, because the intense solar radiation burns the retina.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["eclipse", "safety", "eyes", "damage"],
        "estimated_time_minutes": 3,
        "cognitive_level": 4,
        "additional_data": {}
      }
    },
    {
      "id": "science_eclipse_004",
      "question_text": "What property of light explains why eclipses happen?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Eclipses",
      "subtopic": "Light Properties",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Light travels in straight lines",
      "explanation": "Eclipses occur because light travels in straight lines. When one celestial body moves into the straight-line path of light between two others (e.g., the Moon blocking sunlight from reaching Earth), it casts a shadow, creating an eclipse.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["light", "straight", "lines", "eclipse"],
        "estimated_time_minutes": 3,
        "cognitive_level": 5,
        "additional_data": {}
      }
    },
    {
      "id": "science_eclipse_005",
      "question_text": "What phase is the Moon in during a solar eclipse?",
      "question_type": 2,
      "subject": "Science",
      "topic": "Eclipses",
      "subtopic": "Moon Phases",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "New moon",
      "explanation": "A solar eclipse can only happen during the New Moon phase, when the Moon is positioned between the Earth and the Sun. However, it doesn't happen every New Moon because the Moon's orbit is tilted relative to Earth's orbit around the Sun.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["solar", "eclipse", "phase", "new moon"],
        "estimated_time_minutes": 4,
        "cognitive_level": 6,
        "additional_data": {}
      }
    },
    {
      "id": "science_galaxy_001",
      "question_text": "What is a galaxy?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Galaxies",
      "subtopic": "Definition",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "A huge group of stars, gas, and dust",
      "explanation": "A galaxy is a massive system that contains millions or billions of stars, along with gas, dust, and dark matter, all held together by gravity.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["galaxy", "stars", "definition", "space"],
        "estimated_time_minutes": 4,
        "cognitive_level": 6,
        "additional_data": {}
      }
    },
    {
      "id": "science_galaxy_002",
      "question_text": "What is the name of the galaxy that contains our Solar System?",
      "question_type": 2,
      "subject": "Science",
      "topic": "Galaxies",
      "subtopic": "Milky Way",
      "grade_level": 6,
      "difficulty": 1,
      "answer_key": "Milky Way Galaxy",
      "explanation": "Our Solar System, including the Sun and all its planets, is located within a spiral galaxy called the Milky Way.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["milky way", "galaxy", "solar system", "name"],
        "estimated_time_minutes": 2,
        "cognitive_level": 1,
        "additional_data": {}
      }
    },
    {
      "id": "science_galaxy_003",
      "question_text": "Compared to the entire Milky Way Galaxy, how big is our Solar System?",
      "question_type": 4,
      "subject": "Science",
      "topic": "Galaxies",
      "subtopic": "Scale",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Extremely small",
      "explanation": "The Milky Way Galaxy is vast, containing hundreds of billions of stars. Our Solar System is just one tiny part of one of the galaxy's spiral arms, making it extremely small in comparison to the entire galaxy.",
      "choices": [
        "Very large",
        "About average size",
        "Extremely small"
      ],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["scale", "size", "solar system", "small"],
        "estimated_time_minutes": 3,
        "cognitive_level": 4,
        "additional_data": {}
      }
    },
    {
      "id": "science_galaxy_004",
      "question_text": "Is the Milky Way Galaxy the only galaxy in the universe?",
      "question_type": 2,
      "subject": "Science",
      "topic": "Galaxies",
      "subtopic": "Universe",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "No",
      "explanation": "No, the Milky Way is just one of billions of galaxies in the observable universe. There are many other types of galaxies, such as spiral, elliptical, and irregular galaxies.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["universe", "galaxies", "not only", "no"],
        "estimated_time_minutes": 4,
        "cognitive_level": 6,
        "additional_data": {}
      }
    },
    {
      "id": "science_galaxy_005",
      "question_text": "What force holds a galaxy together?",
      "question_type": 2,
      "subject": "Science",
      "topic": "Galaxies",
      "subtopic": "Gravitational Force",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "Gravity",
      "explanation": "The immense gravitational pull generated by all the mass (stars, gas, dust, and dark matter) in a galaxy is the force that holds it together and keeps the stars orbiting around the galactic center.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["gravity", "force", "holds", "galaxy"],
        "estimated_time_minutes": 4,
        "cognitive_level": 6,
        "additional_data": {}
      }
    },
    {
      "id": "science_stability_001",
      "question_text": "What are two factors that affect the stability of an object?",
      "question_type": 2,
      "subject": "Science",
      "topic": "Stability and Strength",
      "subtopic": "Stability",
      "grade_level": 6,
      "difficulty": 1,
      "answer_key": "Size of base and height of center of gravity",
      "explanation": "An object is more stable if it has a wide base area and a low center of gravity. A wider base makes it harder to tip over, and a lower center of gravity means the weight is closer to the ground.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["stability", "base", "center of gravity", "factors"],
        "estimated_time_minutes": 2,
        "cognitive_level": 2,
        "additional_data": {}
      }
    },
    {
      "id": "science_stability_002",
      "question_text": "Why is a pyramid-shaped building very stable?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Stability and Strength",
      "subtopic": "Pyramid Stability",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Wide base and low center of gravity",
      "explanation": "A pyramid has a very wide base compared to its height, and its center of gravity is very low. These two factors make it extremely difficult to topple over, giving it great stability.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["pyramid", "stable", "wide base", "low gravity"],
        "estimated_time_minutes": 3,
        "cognitive_level": 4,
        "additional_data": {}
      }
    },
    {
      "id": "science_stability_003",
      "question_text": "What are two factors that affect the strength of a structure?",
      "question_type": 2,
      "subject": "Science",
      "topic": "Stability and Strength",
      "subtopic": "Strength",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Type of material and shape of structure",
      "explanation": "The strength of a structure depends on the materials used (e.g., steel is stronger than wood) and the design or shape of the structure (e.g., triangular shapes are very strong).",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["strength", "material", "shape", "structure"],
        "estimated_time_minutes": 3,
        "cognitive_level": 4,
        "additional_data": {}
      }
    },
    {
      "id": "science_stability_004",
      "question_text": "Which shape is known for being very strong and is often used in bridge construction?",
      "question_type": 2,
      "subject": "Science",
      "topic": "Stability and Strength",
      "subtopic": "Strong Shapes",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "Triangle",
      "explanation": "The triangle is a fundamental shape in engineering because it is inherently rigid. When force is applied to a triangle, it is distributed evenly along its sides, making it very strong and resistant to deformation. This is why triangles are commonly used in trusses for bridges and roofs.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["triangle", "strong", "bridge", "construction"],
        "estimated_time_minutes": 4,
        "cognitive_level": 6,
        "additional_data": {}
      }
    },
    {
      "id": "science_stability_005",
      "question_text": "How can recycling materials help in building strong and stable structures?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Stability and Strength",
      "subtopic": "Recycling",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "Provides sustainable building materials",
      "explanation": "Recycling materials like plastic, metal, and concrete provides a sustainable source of raw materials for construction. Using recycled materials helps build strong and stable structures while reducing environmental impact and conserving natural resources.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["recycling", "materials", "sustainable", "construction"],
        "estimated_time_minutes": 4,
        "cognitive_level": 6,
        "additional_data": {}
      }
    },
    {
      "id": "science_tech_pros_cons_001",
      "question_text": "Define the term 'technology'.",
      "question_type": 3,
      "subject": "Science",
      "topic": "Technology",
      "subtopic": "Definition",
      "grade_level": 6,
      "difficulty": 1,
      "answer_key": "Application of science to solve problems",
      "explanation": "Technology refers to the application of scientific knowledge for practical purposes, especially in industry and everyday life. It involves tools, machines, techniques, and systems designed to solve problems and make tasks easier.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["technology", "definition", "application", "science"],
        "estimated_time_minutes": 2,
        "cognitive_level": 2,
        "additional_data": {}
      }
    },
    {
      "id": "science_tech_pros_cons_002",
      "question_text": "Give one example of how technology has improved life in the field of medicine.",
      "question_type": 3,
      "subject": "Science",
      "topic": "Technology",
      "subtopic": "Benefits",
      "grade_level": 6,
      "difficulty": 1,
      "answer_key": "X-ray machines for diagnosis | Vaccines for disease prevention",
      "explanation": "Technology has revolutionized medicine. Examples include X-ray and MRI machines that allow doctors to see inside the body for accurate diagnosis, and vaccines developed through biotechnology that prevent deadly diseases.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["medicine", "technology", "x-ray", "diagnosis"],
        "estimated_time_minutes": 2,
        "cognitive_level": 2,
        "additional_data": {}
      }
    },
    {
      "id": "science_tech_pros_cons_003",
      "question_text": "Give one negative effect of technology on the environment.",
      "question_type": 3,
      "subject": "Science",
      "topic": "Technology",
      "subtopic": "Drawbacks",
      "grade_level": 6,
      "difficulty": 1,
      "answer_key": "Pollution from factories | Electronic waste",
      "explanation": "One major negative effect is pollution. Factories powered by technology can release harmful chemicals and greenhouse gases into the air and water. Additionally, the rapid advancement of electronics leads to a growing problem of electronic waste (e-waste), which is difficult to dispose of safely.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["pollution", "e-waste", "negative", "environment"],
        "estimated_time_minutes": 2,
        "cognitive_level": 2,
        "additional_data": {}
      }
    },
    {
      "id": "science_tech_pros_cons_004",
      "question_text": "How has technology changed the way people communicate?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Technology",
      "subtopic": "Communication",
      "grade_level": 6,
      "difficulty": 2,
      "answer_key": "Instant global communication via internet",
      "explanation": "Technology has transformed communication from slow methods like letters to instant global interaction. Smartphones, the internet, email, and social media allow people to send messages, make video calls, and share information instantly with anyone around the world.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["communication", "internet", "instant", "global"],
        "estimated_time_minutes": 3,
        "cognitive_level": 5,
        "additional_data": {}
      }
    },
    {
      "id": "science_tech_pros_cons_005",
      "question_text": "Why is it important to use technology responsibly?",
      "question_type": 3,
      "subject": "Science",
      "topic": "Technology",
      "subtopic": "Responsible Use",
      "grade_level": 6,
      "difficulty": 3,
      "answer_key": "To minimize harm and maximize benefits",
      "explanation": "Using technology responsibly ensures that we maximize its benefits—like improving health, education, and efficiency—while minimizing its harms, such as environmental damage, privacy invasion, and social isolation. Responsible use promotes sustainability and ethical practices.",
      "choices": [],
      "target_language": "English",
      "metadata": {
        "curriculum_standards": ["DSKP KSSR SAINS TAHUN 6"],
        "tags": ["responsible", "use", "minimize", "maximize"],
        "estimated_time_minutes": 4,
        "cognitive_level": 6,
        "additional_data": {}
      }
    }
  ]
}''';

    try {
      final result = await _importService.importFromJsonString(jsonString);
      print('✅ Year 6 Science questions imported successfully!');
      print('   Total processed: ${result['total_processed']}');
      print('   Successfully imported: ${result['successfully_imported']}');
      print('   Failed imports: ${result['failed_imports']}');
      
      if (result['errors'].length > 0) {
        print('   Errors: ${result['errors']}');
      }
      
      return result;
    } catch (e) {
      print('❌ Error importing questions: $e');
      return {
        'success': false,
        'error': e.toString(),
        'total_processed': 0,
        'successfully_imported': 0,
        'failed_imports': 0,
        'errors': [e.toString()],
      };
    }
  }

  /// You can call this method from anywhere in the app to import the questions
  /// For example, you could call this from the main.dart during initialization
  Future<void> importIfNotAlreadyPresent() async {
    // This would check if the questions are already in the database 
    // and only import them if they're not there yet
  }
}