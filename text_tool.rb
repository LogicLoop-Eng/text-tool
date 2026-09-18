# ============================================================
# برنامه تحلیل و فشرده‌سازی متنی – Text Analyzer Pro (UI+)
# ============================================================
STDOUT.set_encoding("UTF-8") if STDOUT.respond_to?(:set_encoding)
STDIN.set_encoding("UTF-8") if STDIN.respond_to?(:set_encoding)
require "json"
require "time"

RESET = "\e[0m"
RED   = "\e[31m"
GREEN = "\e[32m"
YELLOW= "\e[33m"
BLUE  = "\e[34m"
CYAN  = "\e[36m"
BOLD  = "\e[1m"

STOP_WORDS = %w[
be az baraye ke va dar ba in man to shoma ma ona
مثلا یک خیلی چیز اما که
]

def colored(text, color)
	"#{color}#{text}#{RESET}"
end

def info(msg)
	puts colored("INFO: ", BLUE + BOLD) + msg
end

def warning(msg)
	puts colored("WARNING: ", YELLOW + BOLD) + msg
end

def error(msg)
	puts colored("ERROR: ", RED + BOLD) + msg
end

puts colored("\n=== TEXT ANALYZER TOOL ===", CYAN + BOLD)
info("Enter username (3-15 chars, letters/numbers only)")

username = STDIN.gets.chomp.strip

invalid_user = !(username =~ /^[a-zA-Z0-9_]{3,15}$/)
if invalid_user
	error("Invalid username.")
	exit
end

if File.exist?("#{username}_report.html")
	error("Username '#{username}' already exists!")
	exit
end

# ============================================================
# TEXT ANALYZER CLASS
# ============================================================

class TextAnalyzer
	attr_reader :user_text, :operations, :results

	def initialize(text)
		@user_text = text
		@results = {}

		@operations = {
			1 => { eng: "Uppercase", console: "matn ra bozorg mikonad", fa: "تبدیل به حروف بزرگ" },
			2 => { eng: "Lowercase", console: "matn ra koochak mikonad", fa: "تبدیل به حروف کوچک" },
			3 => { eng: "Trim Whitespace", console: "fasele haye ezafi ra hazf mikonad", fa: "حذف فاصله اضافی" },
			4 => { eng: "Remove Numbers", console: "adad ha ra az matn pak mikonad", fa: "حذف اعداد" },
			5 => { eng: "Remove Symbols", console: "symbol ha va alamat ra hazf mikonad", fa: "حذف کاراکترهای خاص" },
			6 => { eng: "Reverse Text", console: "matn ra baraks mikonad", fa: "برعکس کردن متن" },
			7 => { eng: "Compress", console: "tekrar harf ha ra kam mikonad", fa: "فشرده‌سازی متن" },
			8 => { eng: "Clean Irrelevant Keywords", console: "kalamat bi rabt ra hazf mikonad", fa: "حذف کلمات نامربوط" }
		}
	end

	NORMALIZE_MAP = {
	"khoob" => "khob",
	"khub"  => "khob",
	"khoobe" => "khob",
	"khobe" => "khob",
	"kheili" => "kheili",
	"kheyli" => "kheili",
	"moafagh" => "movafagh",
	"movafaghiat" => "movafaghiyat"
}

def normalize_word(w)
	NORMALIZE_MAP[w] || w
end

	def html_escape(text)
		text.to_s
			.gsub("&", "&amp;")
			.gsub("<", "&lt;")
			.gsub(">", "&gt;")
			.gsub('"', "&quot;")
			.gsub("'", "&#39;")
	end

	def run(selected_ids)
		current = @user_text.dup
		pattern = Regexp.union(STOP_WORDS)
selected_ids.each do |id|
	case id
	when 1
		current = current.upcase
	when 2
		current = current.downcase
	when 3
		current = current.gsub(/\s+/, " ").strip
	when 4
		current = current.gsub(/[0-9۰-۹]/, "")
	when 5
		current = current.gsub(/[^\p{L}\p{N}\s]/u, "")
	when 6
		current = current.reverse
	when 7
		current = current.gsub(/([a-zA-Zآ-ی])\1{2,}/, '\1'.dup)
	when 8
		pattern = Regexp.union(STOP_WORDS)
		current = current.split.reject { |w| STOP_WORDS.include?(w.downcase) }.join(" ")
	end

	@results[id] = current.dup
end

@results
end
def sentiment_summary
	pos_words = %w[
		good great awesome amazing wonderful excellent perfect fantastic
		love loved lovely like liked nice cool beautiful brilliant best
		happy joy joyful enjoyable positive success successful win winner
		useful helpful impressive powerful fast smart creative strong
		smooth clean stable reliable efficient outstanding

		khob khoob khube khoobe
		ali aali
		khoshhal khoshhali khoshhalam
		movafagh movafaghiat movafaghiyat movafaghshodan
		doostdashtani dostdashtani bahal jaleb jazab
		mofid aaliye kheilikhoob kheilikhob
		razi raziam raziat rezayat khoshayand
	]

	neg_words = %w[
		bad terrible awful horrible worst ugly annoying hate hated
		sad angry pain painful problem problems issue issues
		difficult hard slow bug error failure failed fail broken
		useless weak poor boring messy unstable crash

		narahat narahati
		gham ghamgin
		dard dardnak
		moshkel moshkelat
		sakht sakhttar
		shekast shekastkhordan
		asabi naraz naraazi
		zaye biarzeshe biarzeshtarin
		kharab kharabshode
	]

	words = @user_text.downcase.split.map { |w| normalize_word(w) }
	words.reject! { |w| STOP_WORDS.include?(w) }

	pos_count = words.count { |w| pos_words.include?(w) }
	neg_count = words.count { |w| neg_words.include?(w) }

	neutral = [words.size - pos_count - neg_count, 0].max

{ positive: pos_count, negative: neg_count, neutral: neutral }
end

	def word_frequency(limit = 10)
	# 1) توکنیزه کردن
	words = @user_text.downcase.split

	# 2) تمیز کردن حروف اضافی
	words = words.map { |w| w.gsub(/[^a-zA-Z0-9\u0600-\u06FF]/, "") }

	# 3) حذف خالی‌ها
	words.reject!(&:empty?)

	# 4) نرمال‌سازی فینگلیش
	words.map! { |w| normalize_word(w) }

	# 5) حذف Stop Words
	words.reject! { |w| STOP_WORDS.include?(w) }

	# 6) شمارش فراوانی
	freq = Hash.new(0)
	words.each { |w| freq[w] += 1 }

	# 7) مرتب‌سازی و خروجی
	freq.sort_by { |w, c| -c }.first(limit).to_h
	end
end

# ============================================================
# OPERATION SELECTION
# ============================================================

temp = TextAnalyzer.new("") 

puts colored("\n--- AVAILABLE OPERATIONS ---", CYAN + BOLD)

temp.operations.each do |id, op|
	puts "#{id}. #{op[:eng]}  (#{op[:console]})"
end

info("Select operations (example: 1,3,5)")

selected = STDIN.gets.chomp
selected_ids = selected.split(",").map(&:to_i).uniq
valid_ids = temp.operations.keys
selected_ids.select! { |id| valid_ids.include?(id) }

if selected_ids.empty?
	error("No valid operation selected!")
	exit
end

# ============================================================
# TEXT INPUT
# ============================================================

puts colored("\n--- TEXT INPUT ---", CYAN + BOLD)
warning("Enter/Paste your text.")
warning("Press CTRL+D (Linux/Mac) or CTRL+Z then Enter (Windows) when finished.")

lines = []
while line = STDIN.gets
	lines << line.chomp
end

text = lines.join("\n")

if text.strip.empty?
	error("Text cannot be empty!")
	exit
end

# ساخت analyzer و اجرای محاسبات
analyzer = TextAnalyzer.new(text)
results = analyzer.run(selected_ids)
sens = analyzer.sentiment_summary
freq = analyzer.word_frequency(10)

if sens[:positive] == 0 && sens[:negative] == 0
	sentiment_label = "داده احساسی پیدا نشد"
elsif sens[:positive] > sens[:negative]
	sentiment_label = "مثبت ✅"
elsif sens[:negative] > sens[:positive]
	sentiment_label = "منفی ⚠️"
else
	sentiment_label = "خنثی ➖"
end

# ============================================================
# بخش اصلاح شده: تعریف متغیرهای آماری (حل مشکل NameError)
# ============================================================
original_text = text
words = original_text.split(/\s+/)
word_count = words.length
sentence_count = original_text.split(/[.!؟?…]+/).map(&:strip).reject(&:empty?).length


now = Time.now.strftime("%Y/%m/%d %H:%M:%S")

json_output = {
	username:  username,
	input_text: text,
	selected:  selected_ids,
	result:    results,
	sentiment: sens,
	frequency: freq
}.to_json

# ============================================================
# GENERATE TABLE ROWS (با tooltip)
# ============================================================
rows = selected_ids.map do |id|
	eng = analyzer.operations[id][:eng]
	fa  = analyzer.operations[id][:fa]
	res = analyzer.html_escape(results[id])

	"<tr>
		<td class='id-col'>#{id}</td>
		<td class='op-col'>
			<span class='eng-name' data-tooltip='#{fa}'>#{eng}</span>
		</td>
		<td class='result-col'>
			<div class='result-wrapper'>
				<pre class='result-text searchable'>#{res}</pre>
				<button class='copy-btn' onclick='copyResult(this)'>کپی</button>
			</div>
		</td>
	</tr>"
end.join
html = <<~HTML
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
<meta charset="UTF-8">
<title>PRO ANALYZER</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<style>
/* ———— تمام CSS خودت بدون حتی یک تغییر ———— */
*{
box-sizing:border-box;
margin:0;
padding:0;
}

body{
font-family:"Tahoma","Vazirmatn",sans-serif;
background:#0f172a;
color:#e2e8f0;
line-height:1.8;
padding:20px;
}

body.light-mode{
background:#f8fafc;
color:#0f172a;
}

.top-bar{
display:flex;
justify-content:space-between;
align-items:center;
margin-bottom:20px;
padding:18px 22px;
background:rgba(255,255,255,0.05);
border:1px solid rgba(255,255,255,0.08);
border-radius:18px;
backdrop-filter:blur(10px);
}

body.light-mode .top-bar{
background:#ffffff;
border:1px solid #dbeafe;
}

.brand{
font-size:1.4rem;
font-weight:bold;
color:#38bdf8;
}

.user-info{
text-align:left;
font-size:0.95rem;
}

.container{
display:grid;
grid-template-columns: 1.1fr 0.9fr;
gap:20px;
align-items:start;
}

.card{
background:rgba(255,255,255,0.05);
border:1px solid rgba(255,255,255,0.08);
border-radius:18px;
padding:18px;
box-shadow:0 10px 30px rgba(0,0,0,0.2);
}

body.light-mode .card{
background:#ffffff;
border:1px solid #cbd5e1;
box-shadow:0 8px 20px rgba(15,23,42,0.08);
}

.sidebar-content,
.main-content{
display:flex;
flex-direction:column;
gap:20px;
}

.action-bar{
display:flex;
justify-content:space-between;
gap:10px;
}

.icon-btn,
button{
border:none;
background:#1e293b;
color:#fff;
padding:10px 14px;
border-radius:12px;
cursor:pointer;
transition:0.2s;
font-size:0.95rem;
}

body.light-mode .icon-btn,
body.light-mode button{
background:#e2e8f0;
color:#0f172a;
}

.icon-btn:hover,
button:hover{
transform:translateY(-2px);
opacity:0.92;
}

h3{
margin-bottom:14px;
color:#38bdf8;
}

table{
width:100%;
border-collapse:collapse;
margin-top:10px;
overflow:hidden;
border-radius:12px;
}

th,td{
border-bottom:1px solid rgba(255,255,255,0.08);
padding:12px 10px;
text-align:right;
vertical-align:top;
}

body.light-mode th,
body.light-mode td{
border-bottom:1px solid #e2e8f0;
}

th{
background:rgba(56,189,248,0.12);
color:#7dd3fc;
font-weight:bold;
}

body.light-mode th{
background:#e0f2fe;
color:#0369a1;
}

tr:hover{
background:rgba(255,255,255,0.03);
}

body.light-mode tr:hover{
background:#f8fafc;
}

.result-text{
white-space:pre-wrap;
word-break:break-word;
background:rgba(255,255,255,0.03);
padding:10px;
border-radius:10px;
flex:1;
}

body.light-mode .result-text{
background:#f1f5f9;
}

.kpi-grid{
display:grid;
grid-template-columns:repeat(5,1fr);
gap:15px;
}

.kpi-stat{
background:rgba(255,255,255,0.04);
border-radius:14px;
padding:18px;
text-align:center;
}

body.light-mode .kpi-stat{
background:#f1f5f9;
}

#sentimentChart{
display:flex;
gap:6px;
height:42px;
margin-top:10px;
border-radius:10px;
overflow:hidden;
}

mark{
background:#facc15;
color:#000;
padding:2px 4px;
border-radius:4px;
}

.pdf-mode .card{
backdrop-filter:none !important;
background:rgba(255,255,255,0.10) !important;
box-shadow:none !important;
}

body {
	font-size: 14px;
}

@media print {
body {
transform: scale(0.75);
transform-origin: top left;
width:135%;
}
}

#freqChartSimple {
	display: flex;
	flex-direction: column;
	gap: 12px;
	padding: 15px;
	border-radius: 10px;
	overflow-y: auto;
	overflow-x: hidden;
	max-height: 220px;
}

#searchBox {
	width: 100%;
}

#searchInput {
	width: 70% !important;
	padding: 10px 15px;
	font-size: 1.1rem;
	border-radius: 8px;
}

.search-container {
	width: 100%;
	margin-bottom: 20px;
}

.copy-btn {
	background: #1e293b;
	border: none;
	padding: 6px 10px;
	color: #cbd5e1;
	font-size: 0.8rem;
	border-radius: 6px;
	cursor: pointer;
	transition: 0.2s;
}

.copy-btn:hover {
	background: #334155;
}

.copy-btn.copied {
	background: #16a34a !important;
	color: #ffffff !important;
}

/* حالت دارک */
body:not(.light-mode) #freqChartSimple {
	background: #0f1a2b;
}

/* حالت لایت */
body.light-mode #freqChartSimple {
	background: #f1f5f9;
}

#tooltip {
	position: fixed;
}

.tooltip-box {
	position: fixed; /* بسیار مهم: به جای absolute از fixed استفاده کن */
	background: #334155;
	color: #fff;
	padding: 8px 12px;
	border-radius: 6px;
	font-size: 12px;
	z-index: 10000;
	pointer-events: none; /* باعث می‌شود موس با خودِ تولتیپ تداخل نداشته باشد */
	box-shadow: 0 4px 12px rgba(0,0,0,0.3);
	transition: opacity 0.2s;
	white-space: nowrap;
}

body.light-mode .tooltip-box {
	background: #f1f5f9;
	color: #0f172a;
	box-shadow: 0 2px 8px rgba(0,0,0,0.2);
}


.eng-name{
	cursor: help;
	display: inline-block;
}
.header-left {
    display: flex;
    align-items: baseline;
    gap: 6px;
}

.title {
    font-size: 1.5rem;
    font-weight: 800;
    color: #38bdf8;
}

.ver {
    font-size: 0.75rem;
    opacity: 0.6;
}

.header-right {
    display: flex;
    align-items: center;
    gap: 14px;
    font-size: 1rem;
}

.ico {
    opacity: 0.75;
    margin-right: 5px;
}

.sep {
    opacity: 0.4;
    font-size: 1.2rem;
    margin: 0 4px;
}

</style>
</head>
<body>

<div id="reportArea">

<header class="top-bar">

    <div class="header-left">
        <span class="title">PRO ANALYZER</span>
        <span class="ver">v2.0</span>
    </div>

    <div class="header-right">
        <span class="user"><span class="ico">👤</span> #{username}</span>
        <span class="sep">|</span>
        <span class="date"><span class="ico">📅</span> #{now}</span>
    </div>

</header>

<div class="container">

<!-- ستون چپ -->
<aside class="sidebar-content">

<div class="card">
<h3>⚙️ نتایج پردازش</h3>

<div id="copyStatus" style="color:#4ade80;font-size:0.9rem;margin-bottom:10px;display:none;">
✔ متن کپی شد
</div>

<table>
<thead>
<tr>
<th>#</th>
<th>عملیات</th>
<th>نتیجه</th>
</tr>
</thead>
<tbody>
#{rows}
</tbody>
</table>
</div>

<div class="card">
<h3>📈 نمودار احساسات</h3>
<div id="sentimentChart"></div>

<hr style="margin:20px 0;border:none;border-top:1px solid rgba(255,255,255,0.08);">

<h3>📊 نمودار تکرار کلمات</h3>
<div id="freqChartSimple"></div>
</div>

<div class="card">
<h3>📉 شاخص یکنواختی متن (Entropy)</h3>
<p id="entropyValue">در حال محاسبه…</p>
<div style="background:#222;height:10px;border-radius:6px;margin-top:8px;">
	<div id="entropyBar" style="height:10px;width:0%;background:#38bdf8;border-radius:6px;"></div>
</div>
<p id="entropyLabel" style="margin-top:6px;"></p>
<p id="entropyHint"></p>
</div>

</aside>

<!-- ستون راست -->
<main class="main-content">

<div class="action-bar card">
<button class='icon-btn' id='themeBtn'
data-tooltip="تغییر تم تاریک و روشن">🌙</button>
<button class='icon-btn' id='downloadPdfBtn'
data-tooltip="دانلود گزارش PDF">📄</button>
<button class='icon-btn' onclick='exportJSON()'
data-tooltip="دانلود داده‌ها به صورت JSON">💾</button>
<button class='icon-btn' onclick='exportWord()'
data-tooltip="دانلود گزارش Word">📘</button>
</div>

<div class="kpi-grid card">
<div class="kpi-stat"><h2>#{word_count}</h2><p>کلمات</p></div>
<div class="kpi-stat"><h2>#{sentence_count}</h2><p>جملات</p></div>
<div class="kpi-stat"><h2>#{sens[:positive]}</h2><p>مثبت</p></div>
<div class="kpi-stat"><h2>#{sens[:negative]}</h2><p>منفی</p></div>
<div class="kpi-stat"><h2 id="noiseScore">0</h2><p>نویز</p></div>
</div>

<div class="card">
<h3>📊 خلاصه وضعیت</h3>
<p>عملیات انجام‌شده: <b>#{selected_ids.length}</b></p>
<p>وضعیت احساسی: <b>#{sentiment_label}</b></p>
<p>پیچیدگی جملات: <b id="complexityScore">در حال محاسبه…</b></p>
</div>

<div class="card">
<h3>🧾 خلاصه خودکار متن</h3>

<button style="margin-bottom:10px;" onclick="summarizeText()">
تولید خلاصه
</button>

<div id="summaryOutput" class="result-text searchable">
هنوز خلاصه‌ای تولید نشده
</div>
</div>

<div class="card">
<h3>🔎 جستجو و فشرده‌سازی متن</h3>

<div class="search-container">
<input type="text" id="searchInput" placeholder="جستجوی کلمه">
<div style="display:flex;gap:10px;margin-top:10px;">
<button onclick='highlightText()'>یافتن</button>
<button onclick="removeWord()">پاک</button>
</div>
</div>

<button style="width:100%;margin-top:10px;" onclick='compressText()'>فشرده‌سازی متن</button>

<div id="compressionPreview" style="margin-top:15px;">
<h4>پیش‌نمایش فشرده‌سازی</h4>
<p id="compressionRate">کاهش حجم: 0%</p>
<div style="background:#ddd;height:8px;border-radius:4px;width:100%;">
<div id="compressionBar" style="background:#4c8bf5;width:0%;height:8px;border-radius:4px;"></div>
</div>
<pre id="compressOutput" class="searchable result-text" style="margin-top:10px;"></pre>
</div>
</div>

<div class="card">
<h3>📝 متن ورودی</h3>
<div id="originalText" class="result-text searchable" style="max-height:180px;overflow-y:auto;">
#{analyzer.html_escape(original_text)}
</div>
</div>
<div class="card">
<h3>🏷️ استخراج کلمات کلیدی</h3>

<div id="keywordTags" style="display:flex;flex-wrap:wrap;gap:8px;margin-bottom:15px;"></div>

<div style="display:flex;gap:15px;flex-wrap:wrap;">

<div style="flex:1;min-width:220px;">
<h3 style="margin-top:0;">🔍 تشخیص اضافه‌گویی</h3>
<ul id="redundancyList"></ul>
</div>

<div style="flex:1;min-width:220px;">
<h3 style="margin-top:0;">🧠 شناسایی الگوها</h3>
<ul id="patternList"></ul>
</div>

</div>
</div>
</main>
</div>
</div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
<script>
const SENTIMENT_DATA = #{sens.to_json};
const FREQ_DATA = #{freq.to_json};
// متن خام را یک‌بار ذخیره می‌کنیم (مشکل اصلی حل)
function getRawText(){
	const el = document.getElementById("originalText");
	return el ? el.innerText : "";
}
// 1) تشخیص اضافه‌گویی
function detectRedundancy() {

	const text = getRawText().toLowerCase();

	const stopWords = new Set([
		"the","and","is","of","to","in","it","you","that","on",
		"for","with","as","are","was","but","be","at","by","this",
		"have","or","from","an","not","they","his","her",

		"va","ke","az","be","dar","ra","baraye","in","an",
		"ta","shod","ham","mi","man","to"
	]);

	const fillerWords = [
		"really","very","actually","basically","literally",
		"just","maybe","perhaps","somehow",
		"kheili","vaghean","jadan"
	];

	const sentences = text
		.split(/[.!؟?]+/)
		.map(s => s.trim())
		.filter(Boolean);

	const words = text.match(/[a-zA-Z0-9]+/g) || [];

	const ul = document.getElementById("redundancyList");

	let findings = [];

	// =========================================
	// 1. تکرار کلمات
	// =========================================

	const freq = {};

	words.forEach(w => {
		if(w.length > 3 && !stopWords.has(w)){
			freq[w] = (freq[w] || 0) + 1;
		}
	});

	Object.entries(freq)
		.filter(([w,c]) => c >= 4)
		.sort((a,b)=>b[1]-a[1])
		.slice(0,5)
		.forEach(([w,c])=>{
			findings.push(`⚠️ کلمه "${w}" بیش از حد تکرار شده (${c} بار)`);
		});

	// =========================================
	// 2. تکرار عبارت‌های دوکلمه‌ای
	// =========================================

	const phraseFreq = {};

	for(let i=0;i<words.length-1;i++){

		const a = words[i];
		const b = words[i+1];

		if(
			a.length > 2 &&
			b.length > 2 &&
			!stopWords.has(a) &&
			!stopWords.has(b)
		){

			const phrase = a + " " + b;
			phraseFreq[phrase] = (phraseFreq[phrase] || 0) + 1;
		}
	}

	Object.entries(phraseFreq)
		.filter(([p,c]) => c >= 3)
		.slice(0,4)
		.forEach(([p,c])=>{
			findings.push(`🔁 عبارت تکراری "${p}" (${c} بار)`);
		});

	// =========================================
	// 3. filler words
	// =========================================

	const fillerCount = words.filter(w =>
		fillerWords.includes(w)
	).length;

	if(fillerCount >= 5){
		findings.push(`🗣️ متن دارای کلمات اضافه (Filler Words) زیادی است`);
	}

	// =========================================
	// 4. جملات طولانی
	// =========================================

	const longSentences = sentences.filter(s =>
		s.split(/\s+/).length > 30
	);

	if(longSentences.length >= 2){
		findings.push(`📏 ${longSentences.length} جمله بیش‌ازحد طولانی شناسایی شد`);
	}

	// =========================================
	// 5. شروع تکراری جملات
	// =========================================

	const starters = {};

	sentences.forEach(s=>{

		const start = s
			.split(/\s+/)
			.slice(0,2)
			.join(" ");

		if(start.length > 3){
			starters[start] = (starters[start] || 0) + 1;
		}
	});

	Object.entries(starters)
		.filter(([s,c]) => c >= 3)
		.forEach(([s,c])=>{
			findings.push(`🔄 چند جمله با "${s}" شروع شده‌اند (${c} بار)`);
		});

	// =========================================
	// 6. جملات بسیار مشابه
	// =========================================

	function similarity(a,b){

		const aw = [...new Set(a.split(/\s+/))];
		const bw = [...new Set(b.split(/\s+/))];

		const common = aw.filter(x=>bw.includes(x));

		return common.length / Math.max(aw.length,bw.length);
	}

	let similarCount = 0;

	for(let i=0;i<sentences.length;i++){

		for(let j=i+1;j<sentences.length;j++){

			const score = similarity(sentences[i],sentences[j]);

			if(score >= 0.75){
				similarCount++;
			}
		}
	}

	if(similarCount > 0){
		findings.push(`🧠 ${similarCount} جمله بسیار مشابه پیدا شد`);
	}

	// =========================================
	// خروجی نهایی
	// =========================================

	if(findings.length === 0){

		ul.innerHTML = `
			<li style="color:#4ade80;">
				✅ اضافه‌گویی قابل توجهی یافت نشد
			</li>
		`;

	}else{

		ul.innerHTML = findings
			.map(f=>`<li>${f}</li>`)
			.join("");
	}
}
// 2) استخراج کلمات کلیدی
function extractKeywords() {
	const stop = new Set(["از","به","که","و","را","با","در","برای","این"]);

	const words = getRawText().toLowerCase().split(/\s+/)
		.filter(w => w.length > 2 && !stop.has(w));

	const freq = {};
	words.forEach(w => freq[w] = (freq[w] || 0) + 1);

	const sorted = Object.entries(freq)
		.sort((a,b)=>b[1]-a[1])
		.slice(0,10);

	const box = document.getElementById("keywordTags");
	box.innerHTML = sorted.length ?
		sorted.map(([w]) =>
			`<div style="padding:6px 10px;background:#38bdf8;color:#000;border-radius:8px;">${w}</div>`
		).join("") :
		"<p>یافت نشد</p>";
}

// 3) الگوهای متنی
function detectPatterns(text){

	const ul = document.getElementById("patternList");
	if(!ul) return;

	text = text.toLowerCase();

	const words =
		text.match(/[a-zA-Z\u0600-\u06FF]+/g) || [];

	if(words.length < 3){
		ul.innerHTML = "<li>متن برای تشخیص الگو خیلی کوتاه است</li>";
		return;
	}

	const freq = {};

	for(let i=0;i<words.length-1;i++){

		const phrase = words[i] + " " + words[i+1];

		freq[phrase] = (freq[phrase] || 0) + 1;
	}

	const patterns =
		Object.entries(freq)
		.filter(([p,c]) => c >= 2)
		.sort((a,b)=>b[1]-a[1])
		.slice(0,5);

	if(patterns.length === 0){

		ul.innerHTML =
		"<li style='opacity:.7'>الگوی تکراری قابل توجهی پیدا نشد</li>";

		return;
	}

	ul.innerHTML =
		patterns
		.map(([p,c]) => `<li>🔁 "${p}" × ${c}</li>`)
		.join("");
}

// 4) نویز
function calcNoise() {
    var text = getRawText() || "";
    var noise = 0;

    var chars = "@#$%^&*_=+<>~`";

    for (var i = 0; i < text.length; i++) {
        if (chars.indexOf(text[i]) !== -1) {
            noise++;
        }
    }

    document.getElementById("noiseScore").innerText = noise;
}


// 5) پیچیدگی متن
function calcComplexity(text) {
	const s = text.split(/[.!؟?]+/).filter(x=>x.trim().length>0);
	const avg = s.reduce((a,c)=>a + c.split(/\s+/).length , 0) / (s.length || 1);
	return avg.toFixed(1);
}

// 6) Entropy
function calcEntropy(t){

	t = t.replace(/\^Z/g,"");

	const stop = new Set([
	"the","and","is","of","to","in","a","an","that","this"
	]);

	const words =
	t.toLowerCase()
	.match(/[a-zA-Z0-9]+/g) || [];

	const clean = words.filter(w =>
	w.length > 1 && !stop.has(w)
	);

	if(clean.length === 0) return 0;

	const freq = {};

	clean.forEach(w=>{
	freq[w] = (freq[w] || 0) + 1;
	});

	const total = clean.length;
	const unique = Object.keys(freq).length;

	let H = 0;

	for(const w in freq){
	const p = freq[w]/total;
	H -= p*Math.log2(p);
	}

	return H/Math.log2(unique);
}

function interpretEntropy(score) {
	if (score < 0.30) {
		return {
			label: "پایین 🔴",
			text: "متن دارای تنوع واژگانی بسیار پایین و تکرار کلمات زیاد است.",
			color: "#e74c3c"
		};
	} else if (score < 0.60) {
		return {
			label: "متوسط 🟠",
			text: "تنوع واژگان متوسط است و تا حدی تکرار وجود دارد.",
			color: "#f39c12"
		};
	} else {
		return {
			label: "بالا 🟢",
			text: "متن بسیار متنوع از نظر واژگان بوده و یکنواخت نیست.",
			color: "#27ae60"
		};
	}
}

// 7) خلاصه خودکار متن (Auto Summary)
window.summarizeText = function(){

const text = getRawText().trim();

if(!text){
alert("متن خالی است");
return;
}

const sentences = text
.split(/[.!؟?]+/)
.map(s=>s.trim())
.filter(Boolean);

if(sentences.length < 2){
document.getElementById("summaryOutput").innerText =
"متن برای خلاصه‌سازی خیلی کوتاه است";
return;
}

const words =
    text.toLowerCase()
    .match(/[a-zA-Z0-9\u0600-\u06FF]+/g) || [];


const freq = {};
words.forEach(w=>freq[w]=(freq[w]||0)+1);

const scores = sentences.map(s=>{

const ws =
    s.toLowerCase()
    .match(/[a-zA-Z0-9\u0600-\u06FF]+/g) || [];

let score = 0;

ws.forEach(w=>{
score += freq[w] || 0;
});

return {sentence:s,score};

});

scores.sort((a,b)=>b.score-a.score);

const count = Math.min(3,sentences.length);

const top = scores.slice(0,count).map(x=>x.sentence);

document.getElementById("summaryOutput").innerText =
top.join(". ") + ".";
}

// نمودار احساسات (نسخه نهایی)
function drawSentimentChart() {
	const box = document.getElementById("sentimentChart");
	box.innerHTML = "";

	const pos = SENTIMENT_DATA.positive || 0;
	const neg = SENTIMENT_DATA.negative || 0;
	const neu = SENTIMENT_DATA.neutral  || 0;

	const total = pos + neg + neu;

	if (total === 0) {
		box.innerHTML = "<div style='opacity:.6;padding:10px'>داده‌ای برای تحلیل وجود ندارد</div>";
		return;
	}

	const posP = (pos / total) * 100;
	const negP = (neg / total) * 100;
	const neuP = (neu / total) * 100;

	const wrapper = document.createElement("div");
	wrapper.style.padding = "10px 0";

	// نوار گرادیانی
	const bar = document.createElement("div");
	bar.style.height = "20px";
	bar.style.borderRadius = "10px";
	bar.style.background =
		"linear-gradient(to right, #ef4444 0%, #facc15 50%, #22c55e 100%)";
	bar.style.position = "relative";
	bar.style.marginBottom = "14px";

	// نشانگر سفید
	const marker = document.createElement("div");
	marker.style.position = "absolute";
	marker.style.top = "-6px";
	marker.style.left = "0%";
	marker.style.width = "4px";
	marker.style.height = "32px";
	marker.style.background = "#fff";
	marker.style.borderRadius = "2px";
	marker.style.transition = "left 1.3s ease";

	bar.appendChild(marker);

	// لیبل‌ها
	const labels = document.createElement("div");
	labels.style.display = "flex";
	labels.style.justifyContent = "space-between";
	labels.style.fontSize = "0.8rem";
	labels.style.color = "inherit";

	labels.innerHTML = `
		<span>☹ منفی ${negP.toFixed(1)}%</span>
		<span>😐 خنثی ${neuP.toFixed(1)}%</span>
		<span>🙂 مثبت ${posP.toFixed(1)}%</span>
	`;

	wrapper.appendChild(bar);
	wrapper.appendChild(labels);
	box.appendChild(wrapper);

	// محاسبه جای نشانگر
	const score = ((pos - neg) / total + 1) * 50;
	setTimeout(() => {
		marker.style.left = score + "%";
	}, 200);
}
// نمودار فراوانی کلمات (نسخه نهایی - افقی)
function drawFrequencyChart() {
	const container = document.getElementById("freqChartSimple");
	container.innerHTML = "";

	const data = FREQ_DATA;
	const entries = Object.entries(data);
	if (entries.length === 0) return;

	entries.sort((a, b) => b[1] - a[1]);
	const max = Math.max(...entries.map(e => e[1]));

	container.style.display = "flex";
	container.style.flexDirection = "column";
	container.style.gap = "12px";
	container.style.padding = "10px 0";

	entries.slice(0, 8).forEach(([word, count]) => {
		const row = document.createElement("div");
		row.style.display = "flex";
		row.style.alignItems = "center";
		row.style.gap = "10px";

const label = document.createElement("div");
label.textContent = word;
label.style.width = "90px";
label.style.fontSize = "0.8rem";

const countLabel = document.createElement("div");
countLabel.textContent = count;
countLabel.style.width = "30px";
countLabel.style.fontSize = "0.75rem";
countLabel.style.opacity = "0.7";
countLabel.style.textAlign = "right";

const track = document.createElement("div");
track.style.flex = "1";
track.style.height = "14px";
track.style.background = "rgba(255,255,255,.08)";
track.style.borderRadius = "7px";
track.style.overflow = "hidden";

const bar = document.createElement("div");
bar.style.height = "100%";
bar.style.width = "0%";
bar.style.background = "#38bdf8";
bar.style.transition = "width 1.2s ease";

track.appendChild(bar);

row.appendChild(label);
row.appendChild(track);
row.appendChild(countLabel);

container.appendChild(row);

		setTimeout(() => {
			bar.style.width = (count / max) * 100 + "%";
		}, 100);
	});
}
function exportJSON() {

	const text = getRawText().replace(/:::/g, "").trim();

	/* BASIC METRICS */

	const entropy = calcEntropy(text);
	const complexity = calcComplexity(text);

	/* WORDS + FREQUENCY */

	const words =
		text.toLowerCase()
		.match(/[a-zA-Z0-9]+/g) || [];

	const freq = {};

	words.forEach(w => {
		freq[w] = (freq[w] || 0) + 1;
	});

	const keywords = Object.entries(freq)
		.sort((a,b)=>b[1]-a[1])
		.slice(0,10)
		.map(x=>({
			word: x[0],
			count: x[1]
		}));

	/* SUMMARY */

	const sentences = text
		.split(/[.!؟?]+/)
		.map(s=>s.trim())
		.filter(Boolean);

	let summary = [];

	if(sentences.length > 1){

		const wf = {};

		words.forEach(w=>{
			wf[w] = (wf[w] || 0) + 1;
		});

		const scored = sentences.map(s=>{

			const ws =
				s.toLowerCase()
				.match(/[a-zA-Z0-9]+/g) || [];

			let score = 0;

			ws.forEach(w=>{
				score += wf[w] || 0;
			});

			return {
				sentence: s,
				score
			};
		});

		scored.sort((a,b)=>b.score-a.score);

		summary =
			scored
			.slice(0,3)
			.map(x=>x.sentence);
	}

	/* READING TIME */

	const reading_time_minutes =
		(words.length / 200).toFixed(2);

	/* VOCABULARY RICHNESS */

	const uniqueWords =
		new Set(words).size;

	const vocabulary_richness =
		words.length > 0
			? (uniqueWords / words.length).toFixed(2)
			: 0;

	/* LANGUAGE DETECTION */

	const persianChars =
		(text.match(/[\u0600-\u06FF]/g) || []).length;

	const englishChars =
		(text.match(/[a-z]/gi) || []).length;

	let language = "Unknown";

	if(persianChars > englishChars){
		language = "Persian";
	}else if(englishChars > persianChars){
		language = "English";
	}else if(persianChars > 0 && englishChars > 0){
		language = "Mixed";
	}

	/* FINAL JSON */

	const data = {

		text: text,

		analysis: {

			sentiment:
				SENTIMENT_DATA || {},

			entropy:
				entropy,

			complexity:
				complexity,

			reading_time_minutes:
				reading_time_minutes,

			vocabulary_richness:
				vocabulary_richness,

			language:
				language
		},

		keywords:
			keywords,

		summary:
			summary,

		text_operations: [

			"uppercase",
			"lowercase",
			"trim_whitespace",
			"remove_numbers",
			"remove_symbols",
			"reverse_text",
			"compress",
			"clean_irrelevant_keywords"

		]
	};

	/* DOWNLOAD */

	const blob = new Blob(
		[
			JSON.stringify(
				data,
				null,
				2
			)
		],
		{
			type:"application/json"
		}
	);

	const url =
		URL.createObjectURL(blob);

	const a =
		document.createElement("a");

	a.href = url;

	a.download =
		"analysis_report.json";

	a.click();

	URL.revokeObjectURL(url);
}

function exportWord() {

	const content = document.getElementById("reportArea").innerHTML;

	const html = `
	<html>
	<head>
	<meta charset="UTF-8">
	<title>Report</title>
	</head>
	<body>
	${content}
	</body>
	</html>
	`;

	const blob = new Blob([html], {type: "application/msword"});
	const url = URL.createObjectURL(blob);

	const a = document.createElement("a");
	a.href = url;
	a.download = "report.doc";
	a.click();

	URL.revokeObjectURL(url);
}

document.getElementById("themeBtn").onclick = function() {
	document.body.classList.toggle("light-mode");
};

document.getElementById("downloadPdfBtn").onclick = function() {
	const area = document.getElementById("reportArea");
	html2pdf().from(area).save("report.pdf");
};

// ui.js
function copyResult(btn) {
	const text = btn.parentElement.querySelector(".result-text").innerText;
	navigator.clipboard.writeText(text).then(() => {
		btn.classList.add("copied");
		btn.innerText = "✔️ کپی شد";
		setTimeout(() => {
			btn.classList.remove("copied");
			btn.innerText = "کپی";
		}, 1500);
	});
}

// search.js
function highlightText() {
	const q = document.getElementById("searchInput").value.trim();
	clearHighlight();
	if (!q) return;

	const safeQ = q.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

	document.querySelectorAll(".searchable").forEach(el => {
		const text = el.innerText;
		const regex = new RegExp(`(${safeQ})`, "gi");
		el.innerHTML = text.replace(regex, "<mark>$1</mark>");
	});
}

function clearHighlight() {
	document.querySelectorAll(".searchable").forEach(el => {
		el.innerHTML = el.innerText;
	});
}

function removeWord() {
	clearHighlight();
	document.getElementById("searchInput").value = "";
}

// compression.js
function compressText() {

	const original = getRawText();
	if(!original.length) return;

	let out = original.toLowerCase();

	// حذف فاصله اضافی
	out = out.replace(/\s+/g, " ");

	// حذف punctuation
	out = out.replace(/[.,!?;:'"`()-]/g, "");

	// حذف stopwords رایج
	const stopwords = [
		"the","a","an","is","are","of","to",
		"and","in","on","for","with"
	];

	const words = out.split(" ");

	out = words.filter(w => !stopwords.includes(w)).join(" ");

	const ratio = (1 - out.length / original.length) * 100;

	document.getElementById("compressionRate").innerText =
	`کاهش حجم: ${ratio.toFixed(1)}%`;

	document.getElementById("compressionBar").style.width =
	ratio + "%";

	document.getElementById("compressOutput").innerText = out;
}
// اجرای اولیه
detectRedundancy();
extractKeywords();
detectPatterns(getRawText());
calcNoise();
drawSentimentChart();
drawFrequencyChart();
document.getElementById("complexityScore").innerText = calcComplexity(getRawText());

const rawText = getRawText();
const entropyVal = calcEntropy(rawText);
const info = interpretEntropy(entropyVal);

document.getElementById("entropyValue").innerText = entropyVal.toFixed(2);
const entropyBar = document.getElementById("entropyBar");
entropyBar.style.width = (entropyVal * 100) + "%";
entropyBar.style.backgroundColor = info.color;

// اضافه‌کردن متن تفسیر در HTML (ایجاد داینامیک اگر هنوز نیست)
let labelEl = document.getElementById("entropyLabel");
if (!labelEl) {
	labelEl = document.createElement("p");
	labelEl.id = "entropyLabel";
	entropyBar.parentNode.parentNode.appendChild(labelEl);
}
labelEl.textContent = "سطح تنوع واژگان: " + info.label;
labelEl.style.color = info.color;

let descEl = document.getElementById("entropyHint");
if (!descEl) {
	descEl = document.createElement("p");
	descEl.id = "entropyHint";
	entropyBar.parentNode.parentNode.appendChild(descEl);
}
descEl.textContent = info.text;
descEl.style.marginTop = "4px";
descEl.style.fontSize = "0.85rem";
descEl.style.color = "#ccc";

// GLOBAL TOOLTIP (SMART + NICE DISTANCE)
document.addEventListener("mouseover", function (e) {
	const tip = e.target.closest('[data-tooltip]')?.getAttribute("data-tooltip");
	if (tip) {
		// اگر تولتیپ از قبل وجود داشت حذفش کن تا تکراری نشود
		let oldTip = document.querySelector(".tooltip-box");
		if (oldTip) oldTip.remove();

		let div = document.createElement("div");
		div.className = "tooltip-box";
		div.innerHTML = tip;
		document.body.appendChild(div);

		// تنظیم موقعیت اولیه
		moveTooltip(e, div);
	}
});

document.addEventListener("mousemove", function (e) {
	let div = document.querySelector(".tooltip-box");
	if (div) {
		moveTooltip(e, div);
	}
});

document.addEventListener("mouseout", function (e) {
	if (e.target.hasAttribute("data-tooltip") || e.target.closest('[data-tooltip]')) {
		let div = document.querySelector(".tooltip-box");
		if (div) div.remove();
	}
});

// تابع کمکی برای محاسبه موقعیت (جلوگیری از بیرون زدن از صفحه)
function moveTooltip(e, div) {
	let x = e.clientX + 15; // فاصله افقی از موس
	let y = e.clientY + 15; // فاصله عمودی از موس

	// اگر تولتیپ نزدیک لبه سمت راست صفحه بود، آن را به سمت چپ موس ببر
	if (x + div.offsetWidth > window.innerWidth) {
		x = e.clientX - div.offsetWidth - 15;
	}
	// اگر تولتیپ نزدیک لبه پایین صفحه بود، آن را به بالای موس ببر
	if (y + div.offsetHeight > window.innerHeight) {
		y = e.clientY - div.offsetHeight - 15;
	}

	div.style.left = x + "px";
	div.style.top = y + "px";
}

document.addEventListener("mouseleave", function (e) {
	const div = document.querySelector(".tooltip-box");
	if (div) div.remove();
});

</script>
</body>
</html>
HTML

filename = "#{username}_report.html"
File.write(filename, html)

if RUBY_PLATFORM =~ /win32|mingw/
	system("start \"\" \"#{filename}\"")
elsif RUBY_PLATFORM =~ /darwin/
	system("open \"#{filename}\"")
else
	system("xdg-open \"#{filename}\"")
end

puts colored("\nReport generated: #{filename}", GREEN)
