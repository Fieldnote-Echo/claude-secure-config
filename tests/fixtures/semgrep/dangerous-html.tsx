// Tests for dangerous-inner-html rule
import DOMPurify from "dompurify";

function Unsanitized({ content }: { content: string }) {
  // ruleid: dangerous-inner-html
  return <div dangerouslySetInnerHTML={{ __html: content }} />;
}

function Sanitized({ content }: { content: string }) {
  // ruleid: dangerous-inner-html
  return <div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(content) }} />;
}

function Safe({ content }: { content: string }) {
  // ok: dangerous-inner-html
  return <div>{content}</div>;
}
